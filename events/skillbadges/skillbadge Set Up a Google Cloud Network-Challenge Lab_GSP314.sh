

#!/bin/bash

clear
echo "Set Up a Google Cloud Network: Challenge Lab || GSP314"

CYAN='\e[1;36m'
BLUE='\e[1;34m'
RESET='\e[0m'
BOLD='\e[1m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
MAGENTA='\e[1;35m'


echo "${BOLD}${YELLOW}[mat remp] Auto-fetching Project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi
echo -e "✅ Project ID: ${GREEN}$PROJECT_ID${RESET}\n"

echo -e "${MAGENTA}${BOLD}Please copy and paste the following values from your lab instructions:${RESET}"
read -p "Enter Network Name: " VPC_NAME
read -p "Enter Subnet A Name: " SUBNET_A
read -p "Enter Subnet B Name: " SUBNET_B
read -p "Enter Firewall Rule 1 Name (SSH): " FW_1
read -p "Enter Firewall Rule 2 Name (RDP): " FW_2
read -p "Enter Firewall Rule 3 Name (ICMP): " FW_3
read -p "Enter Zone 1 (For Subnet A, e.g., us-central1-a): " ZONE_1
read -p "Enter Zone 2 (For Subnet B, e.g., us-east1-b): " ZONE_2
echo ""

export VPC_NAME SUBNET_A SUBNET_B FW_1 FW_2 FW_3 ZONE_1 ZONE_2
export REGION_1=${ZONE_1%-*}
export REGION_2=${ZONE_2%-*}

echo -e "${GREEN}✅ Variables svd! continue to next.${RESET}"
