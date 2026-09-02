

#!/bin/bash

clear
echo "Debug Apps on Google Kubernetes Engine - GSP736"


BLACK_TEXT=$'\033[38;5;235m'
RED_TEXT=$'\033[38;5;204m'
GREEN_TEXT=$'\033[38;5;114m'
YELLOW_TEXT=$'\033[38;5;222m'
BLUE_TEXT=$'\033[38;5;68m'
MAGENTA_TEXT=$'\033[38;5;182m'
CYAN_TEXT=$'\033[38;5;73m'
WHITE_TEXT=$'\033[38;5;254m'
TEAL=$'\033[38;5;37m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'


# Ask user for ZONE (with validation + color)
while true; do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Enter your GCP Zone (e.g. us-central1-a): ${RESET_FORMAT}"
  read ZONE

  if [[ -n "$ZONE" ]]; then
    break
  else
    echo "${RED_TEXT}ZONE cannot be empty. Please enter a valid zone.${RESET_FORMAT}"
  fi
done

gcloud config set compute/zone $ZONE

export PROJECT_ID=$(gcloud info --format='value(config.project)')

gcloud container clusters get-credentials central --zone $ZONE

git clone https://github.com/xiangshen-dk/microservices-demo.git
cd microservices-demo

kubectl apply -f release/kubernetes-manifests.yaml

sleep 30

gcloud logging metrics create Error_Rate_SLI \
  --description="Error rate for recommendationservice" \
  --log-filter="resource.type=\"k8s_container\" severity=ERROR labels.\"k8s-pod/app\": \"recommendationservice\""

sleep 30

cat > awesome.json <<EOF_END
{
  "displayName": "Error Rate SLI",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Kubernetes Container - logging/user/Error_Rate_SLI",
      "conditionThreshold": {
        "filter": "resource.type = \"k8s_container\" AND metric.type = \"logging.googleapis.com/user/Error_Rate_SLI\"",
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
        "thresholdValue": 0.5
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file="awesome.json"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}              done semangat lagi              ${RESET_FORMAT}"