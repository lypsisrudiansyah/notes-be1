

#!/bin/bash

clear
echo "Implement Cloud Security Fundamentals on Google Cloud - GSP342"

# Run THIS SHOULD ON VM INSTANCES jumpshot from info TASK 5 e.g: orca-jumphost

# This Should Be Read for dynamic Purpose
CLUSTER_NAME="orca-cluster-794"
ZONE="us-west1-b"

# 1. Install the auth plugin using the NEW package name, with a fallback to gcloud components
sudo apt-get update -y
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin || gcloud components install gke-gcloud-auth-plugin --quiet

# 2. Export the required variables
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc

# 3. Authenticate to your cluster
gcloud container clusters get-credentials "$CLUSTER_NAME" --internal-ip --zone="$ZONE"

# 4. Clean up any broken resources
kubectl delete deployment hello-server --ignore-not-found
kubectl delete service hello-server --ignore-not-found

# 5. Deploy the application exactly as the grader expects
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-server --type LoadBalancer --port 8080