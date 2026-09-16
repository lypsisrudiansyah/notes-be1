#!/bin/bash
clear
echo "Developing a REST API with Go and Cloud Run - GSP761 (Fixed Build)"

DETECTED_PROJECT=$(gcloud config get-value project 2>/dev/null)
DETECTED_REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)
DETECTED_REGION=${DETECTED_REGION:-$(gcloud config get-value compute/region 2>/dev/null)}

if [ -n "$DETECTED_PROJECT" ] && [ "$DETECTED_PROJECT" != "(unset)" ]; then
  read -p "Masukkan Project ID [$DETECTED_PROJECT]: " INPUT_PROJECT
  export PROJECT_ID="${INPUT_PROJECT:-$DETECTED_PROJECT}"
else
  read -p "Masukkan Project ID: " PROJECT_ID
  export PROJECT_ID
fi

if [ -n "$DETECTED_REGION" ] && [ "$DETECTED_REGION" != "(unset)" ]; then
  read -p "Masukkan GCP Region [$DETECTED_REGION]: " INPUT_REGION
  export REGION="${INPUT_REGION:-$DETECTED_REGION}"
else
  read -p "Masukkan GCP Region (contoh: europe-west4, us-central1): " REGION
  export REGION
fi

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"

set -e

# Masuk ke direktori lab
cd ~/pet-theory/lab08

# ==========================================
# Task 2: Fix & Deploy Revision 0.1
# ==========================================
echo "1. Menyiapkan main.go (v0.1)..."
cat << 'INNER_EOF' > main.go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
INNER_EOF

cat << 'INNER_EOF' > Dockerfile
FROM scratch
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
INNER_EOF

echo "2. Mengompilasi Go binary v0.1 (Pure Static Binary)..."
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o server .

echo "3. Build & Deploy REST API v0.1..."
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/my-repo/rest-api:0.1"
gcloud run deploy rest-api \
  --image "$REGION-docker.pkg.dev/$PROJECT_ID/my-repo/rest-api:0.1" \
  --region "$REGION" \
  --allow-unauthenticated \
  --max-instances=2

# ==========================================
# Task 3: Setup Firestore & Import Data
# ==========================================
echo ""
echo "4. Memeriksa Database Firestore..."
if ! gcloud firestore databases create --location="$REGION" --type=firestore-native 2>/dev/null; then
  echo ""
  echo ">> PERHATIAN: Pembuatan Firestore via CLI dibatasi."
  echo "1. Buka Navigasi Console -> Firestore."
  echo "2. Klik 'Create Database' -> Pilih 'Native mode'."
  echo "3. Pilih Region: $REGION -> Security rules: Open rules."
  echo "4. Klik 'Create Database'."
  echo ""
  read -p "Tekan [ENTER] jika database Firestore sudah siap di Console..." DUMMY
fi

echo "Mengimpor data customer ke Firestore..."
gcloud storage buckets create "gs://$PROJECT_ID-customer" --default-storage-class=standard --location="$REGION" || true
gcloud storage cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 "gs://$PROJECT_ID-customer"
gcloud beta firestore import "gs://$PROJECT_ID-customer/2019-10-06T20:10:37_43617/"

# ==========================================
# Task 4 & 7: Connect Firestore & Deploy v0.2
# ==========================================
echo "5. Menyiapkan main.go (v0.2)..."
cat << EOF > main.go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"google.golang.org/api/iterator"
)

var client *firestore.Client

func main() {
	var err error
	ctx := context.Background()
	client, err = firestore.NewClient(ctx, "$PROJECT_ID")
	if err != nil {
		log.Fatalf("Error initializing Cloud Firestore client: %v", err)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	r := mux.NewRouter()
	r.HandleFunc("/v1/", rootHandler)
	r.HandleFunc("/v1/customer/{id}", customerHandler)

	log.Println("Pets REST API listening on port", port)
	cors := handlers.CORS(
		handlers.AllowedHeaders([]string{"X-Requested-With", "Authorization", "Origin"}),
		handlers.AllowedOrigins([]string{"https://storage.googleapis.com"}),
		handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "OPTIONS", "PATCH", "CONNECT"}),
	)

	if err := http.ListenAndServe(":"+port, cors(r)); err != nil {
		log.Fatalf("Error launching Pets REST API server: %v", err)
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "{status: 'running'}")
}

func customerHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	ctx := context.Background()
	customer, err := getCustomer(ctx, id)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, \`{"status": "fail", "data": "%s"}\`, err)
		return
	}
	if customer == nil {
		w.WriteHeader(http.StatusNotFound)
		msg := fmt.Sprintf("\"Customer \\"%s\\" not found\"", id)
		fmt.Fprintf(w, fmt.Sprintf(\`{"status": "fail", "data": {"title": %s}}\`, msg))
		return
	}
	amount, err := getAmounts(ctx, customer)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, \`{"status": "fail", "data": "Unable to fetch amounts: %s"}\`, err)
		return
	}
	data, err := json.Marshal(amount)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, \`{"status": "fail", "data": "Unable to fetch amounts: %s"}\`, err)
		return
	}
	fmt.Fprintf(w, fmt.Sprintf(\`{"status": "success", "data": %s}\`, data))
}

type Customer struct {
	Email string \`firestore:"email"\`
	ID    string \`firestore:"id"\`
	Name  string \`firestore:"name"\`
	Phone string \`firestore:"phone"\`
}

func getCustomer(ctx context.Context, id string) (*Customer, error) {
	query := client.Collection("customers").Where("id", "==", id)
	iter := query.Documents(ctx)

	var c Customer
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		err = doc.DataTo(&c)
		if err != nil {
			return nil, err
		}
	}
	return &c, nil
}

func getAmounts(ctx context.Context, c *Customer) (map[string]int64, error) {
	if c == nil {
		return map[string]int64{}, fmt.Errorf("Customer should be non-nil: %v", c)
	}
	result := map[string]int64{
		"proposed": 0,
		"approved": 0,
		"rejected": 0,
	}
	query := client.Collection(fmt.Sprintf("customers/%s/treatments", c.Email))
	if query == nil {
		return map[string]int64{}, fmt.Errorf("Query is nil: %v", c)
	}
	iter := query.Documents(ctx)
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		treatment := doc.Data()
		result[treatment["status"].(string)] += treatment["cost"].(int64)
	}
	return result, nil
}
EOF

echo "6. Mengompilasi Go binary v0.2 (Pure Static Binary)..."
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o server .

echo "7. Build & Deploy REST API v0.2..."
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/my-repo/rest-api:0.2"
gcloud run deploy rest-api \
  --image "$REGION-docker.pkg.dev/$PROJECT_ID/my-repo/rest-api:0.2" \
  --region "$REGION" \
  --allow-unauthenticated \
  --max-instances=2

echo ""
echo "=== Setup Selesai Tanpa Error! Silakan verifikasi 100/100 di Skills Boost. ==="