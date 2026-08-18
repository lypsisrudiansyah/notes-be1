

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


echo -e "${YELLOW}Starting Infrastructure Provisioning...${RESET}"

# Task 1: Create VPC and Subnets
echo -e "${CYAN}Creating VPC Network: $VPC_NAME...${RESET}"
gcloud compute networks create $VPC_NAME \
    --project=$PROJECT_ID \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

echo -e "${CYAN}Creating Subnet A: $SUBNET_A...${RESET}"
gcloud compute networks subnets create $SUBNET_A \
    --project=$PROJECT_ID \
    --region=$REGION_1 \
    --network=$VPC_NAME \
    --range=10.10.10.0/24 \
    --stack-type=IPV4_ONLY

echo -e "${CYAN}Creating Subnet B: $SUBNET_B...${RESET}"
gcloud compute networks subnets create $SUBNET_B \
    --project=$PROJECT_ID \
    --region=$REGION_2 \
    --network=$VPC_NAME \
    --range=10.10.20.0/24 \
    --stack-type=IPV4_ONLY

# Task 2: Create Firewall Rules
echo -e "${CYAN}Creating Firewall Rule 1 (SSH)...${RESET}"
gcloud compute firewall-rules create $FW_1 \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=0.0.0.0/0

echo -e "${CYAN}Creating Firewall Rule 2 (RDP)...${RESET}"
gcloud compute firewall-rules create $FW_2 \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=65535 \
    --action=ALLOW \
    --rules=tcp:3389 \
    --source-ranges=0.0.0.0/24

echo -e "${CYAN}Creating Firewall Rule 3 (ICMP)...${RESET}"
gcloud compute firewall-rules create $FW_3 \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=10.10.10.0/24,10.10.20.0/24

# Task 3: Add VMs to the Network
echo -e "${CYAN}Creating VM: us-test-01...${RESET}"
gcloud compute instances create us-test-01 \
    --project=$PROJECT_ID \
    --zone=$ZONE_1 \
    --subnet=$SUBNET_A \
    --machine-type=e2-standard-2

echo -e "${CYAN}Creating VM: us-test-02...${RESET}"
gcloud compute instances create us-test-02 \
    --project=$PROJECT_ID \
    --zone=$ZONE_2 \
    --subnet=$SUBNET_B \
    --machine-type=e2-standard-2

echo -e "${YELLOW}Waiting 20 seconds for VMs to fully boot before ping test...${RESET}"
sleep 20

# Run Ping Test
INTERNAL_IP=$(gcloud compute instances describe us-test-02 --zone=$ZONE_2 --format='get(networkInterfaces[0].networkIP)')
echo -e "${CYAN}Running Ping Test from us-test-01 to us-test-02...${RESET}"
gcloud compute ssh us-test-01 \
    --zone=$ZONE_1 \
    --project=$PROJECT_ID \
    --quiet \
    --command="ping -c 3 $INTERNAL_IP && ping -c 3 us-test-02.$ZONE_2.c.$PROJECT_ID.internal"

MAGENTA='\e[1;35m'
echo -e "\n${MAGENTA}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║           KEEEP LEARRNING BROOOO                       ║${RESET}"
echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
