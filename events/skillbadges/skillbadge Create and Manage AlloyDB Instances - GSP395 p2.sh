

#!/bin/bash

clear
echo "Create and Manage AlloyDB Instances - GSP395"


echo -e "${CYAN}Task 4: Creating Read Pool Instance 'lab-instance-rp1'...${RESET}"
gcloud alloydb instances create lab-instance-rp1 \
  --cluster=lab-cluster \
  --region=$REGION \
  --instance-type=READ_POOL \
  --cpu-count=2 \
  --read-pool-node-count=2

echo -e "${CYAN}Task 5: Creating Manual Backup 'lab-backup'...${RESET}"
gcloud beta alloydb backups create lab-backup \
  --region=$REGION \
  --cluster=lab-cluster

MAGENTA='\e[1;35m'
BOLD='\e[1m'
RESET='\e[0m'
echo -e "${MAGENTA}${BOLD}║            🎉 AUTOMATION COMPLETED SUCCESSFULLY 🎉           ║${RESET}"
echo "${GREEN}✓ ALL IS GOOD ${RESET_FORMAT}"
echo "Create and Manage AlloyDB Instances - GSP395"
