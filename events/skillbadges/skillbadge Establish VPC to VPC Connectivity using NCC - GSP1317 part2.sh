

#!/bin/bash

clear
echo "Establish VPC to VPC Connectivity using NCC - GSP1317 part1"

GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
WHITE='\e[1;37m'
RESET='\e[0m'
BOLD='\e[1m'



echo -e "${GREEN}${BOLD}▬▬▬▬▬▬ TASK 6: CLEANUP RESOURCES ▬▬▬▬▬▬${RESET}"
echo -e "${YELLOW}[*] Deleting NCC Spokes and Hub...${RESET}"
gcloud network-connectivity spokes delete vpc1-spoke1 --global --quiet
gcloud network-connectivity spokes delete vpc2-spoke2 --global --quiet
gcloud network-connectivity hubs delete ncc-hub --quiet

echo -e "${YELLOW}[*] Deleting DNS Records and Managed Zone...${RESET}"
SQL_INSTANCE=$(gcloud sql instances list --format="value(name)" | head -n 1)
DNS_RECORD=$(gcloud sql instances describe $SQL_INSTANCE --format="value(dnsName)")

gcloud dns record-sets delete $DNS_RECORD --type=A --zone=cloudsql-dns --quiet
gcloud dns managed-zones delete cloudsql-dns --quiet

echo -e "\n${MAGENTA}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║            🎉 LAB COMPLETED SUCCESSFULLY 🎉                ║${RESET}"
echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"