

#!/bin/bash

clear
# https://www.skills.google/games/7395/labs/45386
# Works Manual on Task 1 and 2 Kubernetes initial
# Then Can using shell

echo "Manage Kubernetes in Google Cloud - GSP510"

#dynamically
export REPO_NAME=hello-repo
export INTERVAL=50s
export PROJECT_ID="qwiklabs-gcp-03-49a0fc12c10d"
export CLUSTER_NAME="hello-world-wnv1"
export REGION="us-east1"
export ZONE="us-east1-d"
export NAMESPACE_NAME="gmp-gpks"
export SERVICE_NAME="helloweb-service-0k7u"

# Define color variables (Bright 256-color palette)
BLACK=$(tput setaf 235)      # Deep charcoal
RED=$(tput setaf 196)        # Bright crimson red
GREEN=$(tput setaf 46)       # Vivid neon green
YELLOW=$(tput setaf 226)     # Pure bright yellow
BLUE=$(tput setaf 39)        # Deep sky blue
MAGENTA=$(tput setaf 201)    # Electric vibrant magenta
CYAN=$(tput setaf 51)        # Electric aqua/cyan
WHITE=$(tput setaf 231)      # Bright crisp white

BG_BLACK=$(tput setab 234)   # Very dark gray/black background
BG_RED=$(tput setab 160)     # Solid red background
BG_GREEN=$(tput setab 28)    # Forest green background
BG_YELLOW=$(tput setab 220)  # Amber yellow background
BG_BLUE=$(tput setab 21)     # Royal blue background
BG_MAGENTA=$(tput setab 127) # Dark magenta background
BG_CYAN=$(tput setab 37)     # Teal/cyan background
BG_WHITE=$(tput setab 255)   # Clean white background

BOLD=$(tput bold)
RESET=$(tput sgr0)


echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

gcloud config set compute/zone $ZONE

gcloud container clusters create $CLUSTER_NAME \
--release-channel regular \
--cluster-version latest \
--num-nodes 3 \
--min-nodes 2 \
--max-nodes 6 \
--enable-autoscaling --no-enable-ip-alias

gcloud container clusters update $CLUSTER_NAME --enable-managed-prometheus --zone $ZONE
  
kubectl create ns $NAMESPACE
  
gsutil cp gs://spls/gsp510/prometheus-app.yaml .
 
cat > prometheus-app.yaml <<EOF

apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-test
  labels:
    app: prometheus-test
spec:
  selector:
    matchLabels:
      app: prometheus-test
  replicas: 3
  template:
    metadata:
      labels:
        app: prometheus-test
    spec:
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
      containers:
      - image: nilebox/prometheus-example-app:latest
        name: prometheus-test
        ports:
        - name: metrics
          containerPort: 1234
        command:
        - "/main"
        - "--process-metrics"
        - "--go-metrics"
EOF

kubectl -n $NAMESPACE apply -f prometheus-app.yaml
  
gsutil cp gs://spls/gsp510/pod-monitoring.yaml .
 
cat > pod-monitoring.yaml <<EOF

apiVersion: monitoring.googleapis.com/v1alpha1
kind: PodMonitoring
metadata:
  name: prometheus-test
  labels:
    app.kubernetes.io/name: prometheus-test
spec:
  selector:
    matchLabels:
      app: prometheus-test
  endpoints:
  - port: metrics
    interval: $INTERVAL
EOF

kubectl -n $NAMESPACE apply -f pod-monitoring.yaml
  
gsutil cp -r gs://spls/gsp510/hello-app/ .
  
export PROJECT_ID=$(gcloud config get-value project)
export REGION="${ZONE%-*}"
cd ~/hello-app
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
kubectl -n $NAMESPACE apply -f manifests/helloweb-deployment.yaml

cd manifests/

cat > helloweb-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
      tier: web
  template:
    metadata:
      labels:
        app: hello
        tier: web
    spec:
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 200m
# [END container_helloapp_deployment]
# [END gke_manifests_helloweb_deployment_deployment_helloweb]
---
EOF

cd ..

kubectl delete deployments helloweb -n $NAMESPACE
kubectl -n $NAMESPACE apply -f manifests/helloweb-deployment.yaml

cat > main.go <<EOF
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	// register hello function to handle all requests
	mux := http.NewServeMux()
	mux.HandleFunc("/", hello)

	// use PORT environment variable, or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// start the web server on port and accept requests
	log.Printf("Server listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}

// hello responds to the request with a plain-text "Hello, world" message.
func hello(w http.ResponseWriter, r *http.Request) {
	log.Printf("Serving request: %s", r.URL.Path)
	host, _ := os.Hostname()
	fmt.Fprintf(w, "Hello, world!\n")
	fmt.Fprintf(w, "Version: 2.0.0\n")
	fmt.Fprintf(w, "Hostname: %s\n", host)
}

// [END container_hello_app]
// [END gke_hello_app]

EOF

export PROJECT_ID=$(gcloud config get-value project)
export REGION="${ZONE%-*}"
cd ~/hello-app/

gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2 .
 
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2
  
kubectl set image deployment/helloweb -n $NAMESPACE hello-app=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2
  
kubectl expose deployment helloweb -n $NAMESPACE --name=$SERVICE_NAME --type=LoadBalancer --port 8080 --target-port 8080
 
cd ..

kubectl -n $NAMESPACE apply -f pod-monitoring.yaml

gcloud logging metrics create pod-image-errors \
  --description="awesome lab" \
  --log-filter="resource.type=\"k8s_pod\"	
severity=WARNING"

cat > awesome.json <<EOF_END
{
  "displayName": "Pod Error Alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Kubernetes Pod - logging/user/pod-image-errors",
      "conditionThreshold": {
        "filter": "resource.type = \"k8s_pod\" AND metric.type = \"logging.googleapis.com/user/pod-image-errors\"",
        "aggregations": [
          {
            "alignmentPeriod": "600s",
            "crossSeriesReducer": "REDUCE_SUM",
            "perSeriesAligner": "ALIGN_COUNT"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 0
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": []
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file="awesome.json"

echo "${BG_GREEN}${BOLD} Seems Like Completed! ${RESET}"
