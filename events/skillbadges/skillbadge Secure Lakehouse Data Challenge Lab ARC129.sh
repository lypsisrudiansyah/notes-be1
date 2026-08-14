

#!/bin/bash

clear
echo "Secure Lakehouse Data Challenge Lab || ARC129"

GREEN='\e[38;5;48m'
CYAN='\e[38;5;51m'
YELLOW='\e[38;5;214m'
MAGENTA='\e[38;5;135m'
RED='\e[38;5;196m'
RESET='\e[0m'
BOLD='\e[1m'


export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
echo -e "${YELLOW}${BOLD}[*] Project ID: ${PROJECT_ID}${RESET}\n"

echo -e "${CYAN}${BOLD}⚠️  ATTENTION: USER 2 CREDENTIALS REQUIRED ⚠️${RESET}"
read -p "Enter User 2 Email (e.g., student-xx-xxxx@qwiklabs.net): " USER_2
echo ""

# Save state securely for Command 2
cat > ~/.jakobi_env <<ENV_EOF
export PROJECT_ID="${PROJECT_ID}"
export USER_2="${USER_2}"
ENV_EOF

echo -e "${GREEN}${BOLD}>>> Var loccked! Proceed to Command (2 of 2). <<<${RESET}"

sleep 35

BLUE='\e[1;34m'

source ~/.jakobi_env

echo -e "${CYAN}${BOLD} ~~ Step 1: Creating BigQuery Dataset & Connection...${RESET}"
bq mk --location=US online_shop 2>/dev/null || true
bq mk --connection --location=US --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE user_data_connection 2>/dev/null || true

echo -e "${YELLOW}${BOLD} ~~ Step 2: Granting BigLake Service Account Permissions...${RESET}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.US.user_data_connection | jq -r '.cloudResource.serviceAccountId')
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/storage.objectViewer --quiet

echo -e "${MAGENTA}${BOLD} ~~ Step 3: Creating BigLake Table Definition...${RESET}"
bq mkdef --autodetect --connection_id=$PROJECT_ID.US.user_data_connection --source_format=CSV "gs://$PROJECT_ID-bucket/user-online-sessions.csv" > /tmp/tabledef.json
bq mk --external_table_definition=/tmp/tabledef.json --project_id=$PROJECT_ID online_shop.user_online_sessions 2>/dev/null || true

echo -e "${YELLOW}${BOLD} ~~ Step 4: Removing User 2 IAM Policy Binding...${RESET}"
gcloud projects remove-iam-policy-binding ${PROJECT_ID} --member="user:$USER_2" --role="roles/storage.objectViewer" --quiet

rm /tmp/tabledef.json ~/.jakobi_env 2>/dev/null

echo -e "\n${GREEN}${BOLD}>>> SCRIPT COMPLETE! Please follow the UI steps below to finish Task 2. <<<${RESET}"