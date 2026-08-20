

#!/bin/bash

clear
echo "Create a Streaming Data Lake on Cloud Storage - ARC110"

#!/bin/bash
GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
WHITE='\e[1;37m'
RED='\e[1;31m'
RESET='\e[0m'
BOLD='\e[1m'


echo -e "${YELLOW}${BOLD} Auto-fetching Project and Region...${RESET}"
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)

if [[ -z "$ZONE" ]]; then
    read -p "Please enter the lab Zone (e.g., us-east1-c): " ZONE
    export ZONE
fi

export REGION=${ZONE%-*}
gcloud config set compute/region $REGION 2>/dev/null

echo -e "✅ Project ID: ${GREEN}$PROJECT_ID${RESET}"
echo -e "✅ Region:     ${GREEN}$REGION${RESET}\n"

echo -e "${MAGENTA}${BOLD}⚠️  PLEASE ENTER THE EXACT VALUES FROM YOUR LAB MANUAL: ⚠️${RESET}\n"
read -p "1. Enter the Pub/Sub topic name: " TOPIC
read -p "2. Enter the Message input: " MESSAGE
read -p "3. Enter the Cloud Storage bucket name: " BUCKET

echo -e "\n${BLUE}${BOLD} Disabling and Re-enabling Dataflow API (Lab Requirement)...${RESET}"
gcloud services disable dataflow.googleapis.com --force --quiet
gcloud services enable dataflow.googleapis.com cloudscheduler.googleapis.com appengine.googleapis.com pubsub.googleapis.com
sleep 15

echo -e "\n${BLUE}${BOLD} Task 1 & 3: Creating Pub/Sub Topic and GCS Bucket...${RESET}"
gcloud pubsub topics create $TOPIC --quiet
gsutil mb -l $REGION gs://$BUCKET

echo -e "\n${BLUE}${BOLD} Task 2: Setting up App Engine and Cloud Scheduler...${RESET}"
# App Engine Region Mapping
AE_REGION=$REGION
if [[ "$REGION" == "us-central1" ]]; then
  AE_REGION="us-central"
elif [[ "$REGION" == "europe-west1" ]]; then
  AE_REGION="europe-west"
fi

gcloud app create --region=$AE_REGION --quiet 2>/dev/null || true

gcloud scheduler jobs create pubsub publisher-job \
    --schedule="* * * * *" \
    --topic=$TOPIC \
    --message-body="$MESSAGE" \
    --location=$REGION \
    --quiet

echo -e "${YELLOW}Manually triggering the scheduler to start the data stream...${RESET}"
gcloud scheduler jobs run publisher-job --location=$REGION --quiet || true

echo -e "\n${BLUE}${BOLD} Task 4: Preparing Python Virtual Environment for Dataflow...${RESET}"
cd ~
python3 -m venv df-env
source df-env/bin/activate

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics
pip install -U pip
pip install -U -r requirements.txt

# Remove the wait_until_finish line so the terminal doesn't hang indefinitely
sed -i 's/result.wait_until_finish()/# result.wait_until_finish()/g' PubSubToGCS.py

echo -e "\n${BLUE}${BOLD} Task 4: Submitting Dataflow Pipeline...${RESET}"
python PubSubToGCS.py \
    --project=$PROJECT_ID \
    --region=$REGION \
    --input_topic=projects/$PROJECT_ID/topics/$TOPIC \
    --output_path=gs://$BUCKET/samples/output \
    --runner=DataflowRunner \
    --window_size=2 \
    --num_shards=2 \
    --temp_location=gs://$BUCKET/temp \
    --worker_machine_type=e2-standard-2 \
    --worker_disk_type=pd-standard

echo -e "${MAGENTA}${BOLD}║  🎉 DATAFLOW JOB SUBMITTED! PLEASE READ THE NOTE BELOW!    ║${RESET}"
echo -e "${WHITE}${BOLD}NOTE: The Dataflow job takes about 3 to 5 minutes to fully start up and write output files to your bucket. Check the Dataflow UI in the Google Cloud Console. Once you see files appearing in your Cloud Storage Bucket, click 'Check my progress'!${RESET}"