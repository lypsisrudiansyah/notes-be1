

#!/bin/bash

clear
echo "Implement Cloud Security Fundamentals on Google Cloud - GSP342"


# Prompt for the variables listed in your specific lab manual
read -p "Enter CUSTOM_SECURITY_ROLE (e.g., orca_storage_editor_...): " CUSTOM_SECURITY_ROLE
read -p "Enter SERVICE_ACCOUNT (e.g., orca-private-cluster-...-sa): " SERVICE_ACCOUNT
read -p "Enter CLUSTER_NAME (e.g., orca-cluster-...): " CLUSTER_NAME
read -p "Enter ZONE (e.g., europe-west4-c): " ZONE

echo -e "\nStarting Lab Tasks. Configuring compute zone..."
gcloud config set compute/zone "$ZONE"

# ----------------- TASK 1 -----------------
echo "Task 1: Creating custom security role..."
cat > role-definition.yaml <<EOF
title: "$CUSTOM_SECURITY_ROLE"
description: "Permissions"
stage: "ALPHA"
includedPermissions:
- storage.buckets.get
- storage.objects.get
- storage.objects.list
- storage.objects.update
- storage.objects.create
EOF
gcloud iam roles create "$CUSTOM_SECURITY_ROLE" --project "$DEVSHELL_PROJECT_ID" --file role-definition.yaml

# ----------------- TASK 2 -----------------
echo "Task 2: Creating service account..."
gcloud iam service-accounts create "$SERVICE_ACCOUNT" --display-name="Orca Private Cluster Service Account"

# ----------------- TASK 3 -----------------
echo "Task 3: Binding IAM roles to the service account..."
for role in roles/monitoring.viewer roles/monitoring.metricWriter roles/logging.logWriter "projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_SECURITY_ROLE"; do
  gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
      --member "serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
      --role "$role"
done

# ----------------- TASK 4 -----------------
echo "Task 4: Creating private GKE cluster (This will take ~5 minutes)..."
JUMPHOST_IP=$(gcloud compute instances describe orca-jumphost --zone="$ZONE" --format='get(networkInterfaces[0].networkIP)')

gcloud container clusters create "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --num-nodes=1 \
    --network="orca-build-vpc" \
    --subnetwork="orca-build-subnet" \
    --master-ipv4-cidr="172.16.0.64/28" \
    --enable-master-authorized-networks \
    --master-authorized-networks="${JUMPHOST_IP}/32" \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --service-account="$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

# ----------------- TASK 5 -----------------
echo "Task 5: Deploying application to cluster (Bypassing SSH entirely)..."
# We inject a startup script into the VM and reset it. When the VM wakes up, it runs these commands locally as the root user.
cat > startup.sh <<EOF
#! /bin/bash
sudo apt-get update -y
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export HOME=/root
export KUBECONFIG=/root/.kube/config

gcloud container clusters get-credentials $CLUSTER_NAME --internal-ip --zone=$ZONE
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-server --name orca-hello-service --type LoadBalancer --port 80 --target-port 8080
EOF

gcloud compute instances add-metadata orca-jumphost \
  --zone="$ZONE" \
  --metadata-from-file startup-script=startup.sh

gcloud compute instances reset orca-jumphost --zone="$ZONE" --quiet

echo -e "\n========================================================"
echo "DONE! The Jumphost VM is now rebooting and deploying your app."
echo "Wait exactly 3 to 4 minutes, then go click 'Check my progress' on all tasks!"
echo "========================================================"