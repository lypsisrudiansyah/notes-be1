

#!/bin/bash

clear
echo "Develop your Google Cloud Network - GSP321"

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
BOLD='\e[1m'
RESET='\e[0m'

echo -e "\n${MAGENTA}${BOLD} 🚀 Starting santuy Execution (GSP321: Part 2 of 2)... ${RESET}\n"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
export ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

echo -e "${BOLD}${CYAN}[santuy] Task 5: Creating Kubernetes cluster (griffin-dev)...${RESET}"
echo -e "${BOLD}${YELLOW}⏳ This process takes roughly 4 to 6 minutes. Please wait...${RESET}"
gcloud container clusters create griffin-dev \
  --network griffin-dev-vpc \
  --subnetwork griffin-dev-wp \
  --machine-type e2-standard-4 \
  --num-nodes 2  \
  --zone $ZONE \
  --quiet

gcloud container clusters get-credentials griffin-dev --zone $ZONE

echo -e "\n${BOLD}${CYAN}[santuy] Task 6: Preparing the Kubernetes cluster...${RESET}"
cd ~/
gsutil cp -r gs://spls/gsp321/wp-k8s .
cd wp-k8s

cat > wp-env.yaml <<EOF_END
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-volumeclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: database
type: Opaque
stringData:
  username: wp_user
  password: stormwind_rules
EOF_END

kubectl apply -f wp-env.yaml

gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$PROJECT_ID.iam.gserviceaccount.com --quiet
kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json

echo -e "\n${BOLD}${CYAN}[santuy] Task 7: Creating WordPress deployment...${RESET}"
INSTANCE_ID=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')

cat > wp-deployment.yaml <<EOF_END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
        - image: wordpress
          name: wordpress
          env:
          - name: WORDPRESS_DB_HOST
            value: 127.0.0.1:3306
          - name: WORDPRESS_DB_USER
            valueFrom:
              secretKeyRef:
                name: database
                key: username
          - name: WORDPRESS_DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: database
                key: password
          ports:
            - containerPort: 80
              name: wordpress
          volumeMounts:
            - name: wordpress-persistent-storage
              mountPath: /var/www/html
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.33.2
          command: ["/cloud_sql_proxy",
                    "-instances=$INSTANCE_ID=tcp:3306",
                    "-credential_file=/secrets/cloudsql/key.json"]
          securityContext:
            runAsUser: 2 
            allowPrivilegeEscalation: false
          volumeMounts:
            - name: cloudsql-instance-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
      volumes:
        - name: wordpress-persistent-storage
          persistentVolumeClaim:
            claimName: wordpress-volumeclaim
        - name: cloudsql-instance-credentials
          secret:
            secretName: cloudsql-instance-credentials
EOF_END

kubectl apply -f wp-deployment.yaml
kubectl apply -f wp-service.yaml

echo -e "\n${BOLD}${YELLOW}⏳ Waiting for LoadBalancer External IP to be assigned...${RESET}"
WP_IP=""
while [[ -z "$WP_IP" || "$WP_IP" == "pending" ]]; do
    WP_IP=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    sleep 5
done
echo -e "${GREEN}✅ WordPress IP found: $WP_IP${RESET}"

echo -e "\n${BOLD}${CYAN}[santuy] Task 8: Enabling monitoring and creating Uptime Check...${RESET}"
gcloud monitoring uptime create http wordpress-uptime-check \
  --display-name="WordPress Uptime" \
  --path="/" \
  --host="$WP_IP" \
  --quiet

echo -e "\n${BOLD}${CYAN}[santuy] Task 9: Providing Editor access for the additional engineer...${RESET}"
SECOND_USER=$(gcloud projects get-iam-policy $PROJECT_ID --format=json | jq -r '.bindings[] | select(.role == "roles/viewer").members[]' | grep 'user:' | cut -d':' -f2 | head -n 1)

if [ ! -z "$SECOND_USER" ]; then
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="user:$SECOND_USER" \
      --role="roles/editor" \
      --quiet
    echo -e "${GREEN}✅ Editor role granted to $SECOND_USER${RESET}"
else
    echo -e "${RED}⚠️ Could not automatically detect the second user. You may need to assign it manually.${RESET}"
fi



export USER_2="$SECOND_USER" # Paste exact Username 2 here

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
    --member="user:$USER_2" \
    --role="roles/editor"

# ==============================================================================
# COMPLETION
# ==============================================================================
echo -e "${MAGENTA}${BOLD}║            🎉 AUTOMATION COMPLETED SUCCESSFULLY 🎉           ║${RESET}"
echo -e "${GREEN}${BOLD}You can now safely click ALL 'Check my progress' buttons in your lab manual.${RESET}"