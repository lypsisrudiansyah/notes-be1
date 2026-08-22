

#!/bin/bash

clear
echo "Develop your Google Cloud Network - GSP321"

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
BOLD='\e[1m'
RESET='\e[0m'

echo -e "${BOLD}${YELLOW}[santuy] Auto-fetching Project, Zone, and Region...${RESET}"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)

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
# MAIN SCRIPT EXECUTION - PART 1
# ==============================================================================

echo -e "${BOLD}${CYAN}[santuy] Task 1: Creating development VPC manually...${RESET}"
gcloud compute networks create griffin-dev-vpc --subnet-mode custom --quiet
gcloud compute networks subnets create griffin-dev-wp --network=griffin-dev-vpc --region $REGION --range=192.168.16.0/20 --quiet
gcloud compute networks subnets create griffin-dev-mgmt --network=griffin-dev-vpc --region $REGION --range=192.168.32.0/20 --quiet

echo -e "\n${BOLD}${CYAN}[santuy] Task 2: Creating production VPC manually...${RESET}"
gcloud compute networks create griffin-prod-vpc --subnet-mode custom --quiet
gcloud compute networks subnets create griffin-prod-wp --network=griffin-prod-vpc --region $REGION --range=192.168.48.0/20 --quiet
gcloud compute networks subnets create griffin-prod-mgmt --network=griffin-prod-vpc --region $REGION --range=192.168.64.0/20 --quiet

echo -e "\n${BOLD}${CYAN}[santuy] Task 3: Creating bastion host with dual network interfaces...${RESET}"
gcloud compute instances create bastion \
    --network-interface=network=griffin-dev-vpc,subnet=griffin-dev-mgmt \
    --network-interface=network=griffin-prod-vpc,subnet=griffin-prod-mgmt \
    --tags=ssh --zone=$ZONE --quiet

gcloud compute firewall-rules create fw-ssh-dev --source-ranges=0.0.0.0/0 --target-tags ssh --allow=tcp:22 --network=griffin-dev-vpc --quiet
gcloud compute firewall-rules create fw-ssh-prod --source-ranges=0.0.0.0/0 --target-tags ssh --allow=tcp:22 --network=griffin-prod-vpc --quiet

echo -e "\n${BOLD}${CYAN}[santuy] Task 4: Creating and configuring Cloud SQL Instance...${RESET}"
echo -e "${BOLD}${YELLOW}⏳ This process takes roughly 5 to 8 minutes. Please wait...${RESET}"
gcloud sql instances create griffin-dev-db \
    --database-version=MYSQL_5_7 \
    --region=$REGION \
    --root-password='stormwind_rules' \
    --quiet

gcloud sql databases create wordpress --instance=griffin-dev-db --quiet
gcloud sql users create wp_user --instance=griffin-dev-db --password=stormwind_rules --quiet

echo -e "\n${GREEN}${BOLD}✅ Part 1 complete! Please proceed to Command 2 of 2.${RESET}"