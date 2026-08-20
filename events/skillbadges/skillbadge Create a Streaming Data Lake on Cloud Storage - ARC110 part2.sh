#!/bin/bash
GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
WHITE='\e[1;37m'
RESET='\e[0m'
BOLD='\e[1m'


export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)
export REGION=${ZONE%-*}

read -p "1. Enter the Pub/Sub topic name: " TOPIC
read -p "2. Enter the Cloud Storage bucket name: " BUCKET

echo -e "\n${BLUE}${BOLD} Activating Virtual Environment...${RESET}"
cd ~/python-docs-samples/pubsub/streaming-analytics
source ~/df-env/bin/activate

echo -e "\n${BLUE}${BOLD} Submitting Dataflow Pipeline with full disk path...${RESET}"
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
    --worker_disk_type="compute.googleapis.com/projects/$PROJECT_ID/zones/$ZONE/diskTypes/pd-standard"

echo -e "${MAGENTA}${BOLD}║  🎉 DATAFLOW JOB SUBMITTED SUCCESSFULLY!                   ║${RESET}"
echo -e "${WHITE}${BOLD}NOTE: Check the Dataflow UI in the Google Cloud Console. It will take about 3 to 5 minutes to spin up the workers. Once you see output files in your Cloud Storage Bucket, click 'Check my progress'!${RESET}"