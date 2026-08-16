

#!/bin/bash

clear
echo "Monitor and Log with Google Cloud Observability || GSP338"


clear

# ==============================================================================
# Color Variables & Mociao Branding
# ==============================================================================
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
BOLD='\e[1m'
RESET='\e[0m'

echo -e "${BLUE}--------------------------------------------------------------------------------${RESET}\n"

# ==============================================================================
# PRE-FLIGHT CHECKS & VARIABLES (DYNAMIC AUTO-FETCH)
# ==============================================================================
echo -e "${BOLD}${YELLOW}[Mociao] Auto-fetching Project, Zone, and Region...${RESET}"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

export ZONE=$(gcloud compute instances list --project="$PROJECT_ID" --format="value(zone)" --limit=1 2>/dev/null)

if [[ -z "$ZONE" ]]; then
    echo -e "${BOLD}${RED}⚠️ Could not auto-detect the default zone via gcloud metadata.${RESET}"
    echo -ne "${BOLD}${CYAN}Please enter the lab Zone (e.g., us-east1-c): ${RESET}"
    read ZONE
    export ZONE
fi

export REGION=${ZONE%-*}

gcloud config set compute/zone $ZONE 2>/dev/null
gcloud config set compute/region $REGION 2>/dev/null

echo -e "✅ Project ID: ${GREEN}$PROJECT_ID${RESET}"
echo -e "✅ Zone:       ${GREEN}$ZONE${RESET}"
echo -e "✅ Region:     ${GREEN}$REGION${RESET}\n"
echo -e "${BLUE}--------------------------------------------------------------------------------${RESET}\n"

# ==============================================================================
# USER INPUT
# ==============================================================================
echo -e "${BOLD}${YELLOW}⚠️ ATTENTION: Check your lab instructions for the following values: ${RESET}"

echo -ne "${BOLD}${CYAN}Enter the Custom Metric Name (from Task 3): ${RESET}"
read METRIC_NAME

echo -ne "${BOLD}${CYAN}Enter the Alert Threshold value (from Task 5): ${RESET}"
read THRESHOLD_VALUE

echo -e "\n${BLUE}--------------------------------------------------------------------------------${RESET}\n"

# ==============================================================================
# MAIN SCRIPT EXECUTION
# ==============================================================================

echo -e "${BOLD}${CYAN}[Mociao] Enabling Monitoring API...${RESET}"
gcloud services enable monitoring.googleapis.com

echo -e "\n${BOLD}${CYAN}[Mociao] Task 2: Configuring video-queue-monitor instance...${RESET}"
export INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --zone="$ZONE" --format="get(id)")

gcloud compute instances stop video-queue-monitor --zone $ZONE --quiet

cat > startup-script.sh <<EOF_START
#!/bin/bash

export PROJECT_ID=$PROJECT_ID
export ZONE=$ZONE
export REGION=$REGION

# Install Golang
sudo apt update && sudo apt -y
sudo apt-get install wget git -y
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=\$PATH:/usr/local/go/bin

# Install Ops Agent 
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

# Setup Go environment
mkdir -p /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

# Install Video Queue Source Code
cd /work/go
mkdir video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

# Get Stackdriver modules
go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

export MY_PROJECT_ID=$PROJECT_ID
export MY_GCE_INSTANCE_ID=$INSTANCE_ID
export MY_GCE_INSTANCE_ZONE=$ZONE

# Initialize and run
cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_START

echo -e "${BOLD}${YELLOW}Applying startup script and restarting instance...${RESET}"
gcloud compute instances add-metadata video-queue-monitor \
  --zone $ZONE \
  --metadata-from-file startup-script=startup-script.sh

gcloud compute instances start video-queue-monitor --zone $ZONE --quiet

echo -e "\n${BOLD}${CYAN}[Mociao] Task 3: Creating custom log metric ($METRIC_NAME)...${RESET}"
gcloud logging metrics create $METRIC_NAME \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=~"file_format\: ([4,8]K).*"'

echo -e "\n${BOLD}${CYAN}[Mociao] Task 5: Creating Notification Channel and Alert Policy...${RESET}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "Mociao Alerts",
  "description": "Video Queue Monitoring",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json" --quiet
EMAIL_CHANNEL_ID=$(gcloud beta monitoring channels list --format="value(name)" --limit=1)

cat > alert-policy.json <<EOF_END
{
  "displayName": "High Resolution Video Alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - logging/user/$METRIC_NAME",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$METRIC_NAME\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": $THRESHOLD_VALUE
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$EMAIL_CHANNEL_ID"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file=alert-policy.json --quiet

# ==============================================================================
# COMPLETION
# ==============================================================================
echo -e "\n${MAGENTA}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║        done check UI STEP                                ║${RESET}"
echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${GREEN}${BOLD}You can now safely check your progress for Tasks 1, 2, 3, and 5.${RESET}"
echo -e "${CYAN}${BOLD}Follow the manual steps below to complete Task 4!${RESET}\n"

### Kurang Buat Alerting Policies Cari VM Instance ... user naming kinda .. high_res_video_metric step 3: 1 minute,rate , Step 4 any thres,  above thres, 4; 5 next; naming policy  maybe canbe random : High Resolution Video Upload Rate Alert wait for 20 seconds at least  and all done