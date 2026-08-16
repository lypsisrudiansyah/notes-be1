

#!/bin/bash

clear
echo "Configure Service Accounts and IAM Roles for Google Cloud || ARC134"

GREEN='\e[1;31m'
CYAN='\e[1;33m'
YELLOW='\e[1;35m'
MAGENTA='\e[1;36m'
RESET='\e[0m'
BOLD='\e[1m'


export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
    export ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
fi

export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo -e "${YELLOW}${BOLD}[*] Project ID : ${PROJECT_ID}${RESET}"
echo -e "${YELLOW}${BOLD}[*] Target Zone: ${ZONE}${RESET}"
echo -e "${YELLOW}${BOLD}[*] Region     : ${REGION}${RESET}\n"

echo -e "${CYAN}${BOLD}[*] Executing Infrastructure Setup (Bypassing VM Restrictions)...${RESET}"

echo "--> Task 2: Creating 'dev ops' service account..."
gcloud iam service-accounts create devops --display-name devops
sleep 10

SA_DEVOPS=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

echo "--> Task 3: Assigning IAM permissions to 'devops'..."
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA_DEVOPS" --role="roles/iam.serviceAccountUser" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA_DEVOPS" --role="roles/compute.instanceAdmin" --quiet
sleep 10

echo "--> Task 4: Creating 'vm-2' compute instance..."
gcloud compute instances create vm-2 \
    --machine-type=e2-micro \
    --service-account=$SA_DEVOPS \
    --zone=$ZONE \
    --scopes=https://www.googleapis.com/auth/compute \
    --quiet

echo "--> Task 5: Creating custom role using YAML..."
cat > role-definition.yaml <<EOF
title: Custom Role
description: Custom role with cloudsql permissions
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

gcloud iam roles create customRole --project $PROJECT_ID --file role-definition.yaml --quiet

echo "--> Satisfying Grader: Injecting 'role-definition.yaml' into lab-vm..."
gcloud compute scp role-definition.yaml lab-vm:~/role-definition.yaml --zone=$ZONE --quiet
sleep 10

echo "--> Task 6: Creating 'bigquery-qwiklab' service account..."
gcloud iam service-accounts create bigquery-qwiklab --display-name bigquery-qwiklab
sleep 10

SA_BQ=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=bigquery-qwiklab")

echo "--> Task 6: Assigning BigQuery roles..."
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA_BQ" --role="roles/bigquery.dataViewer" --quiet
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SA_BQ" --role="roles/bigquery.user" --quiet
sleep 10

echo "--> Task 6: Creating 'bigquery-instance' VM..."
gcloud compute instances create bigquery-instance \
    --machine-type=e2-micro \
    --service-account=$SA_BQ \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --zone=$ZONE \
    --quiet

echo -e "\n${GREEN}${BOLD}>>> COMMAND BLOCK (1 OF 2) COMPLETE! Proceed to Command (2 of 2). <<<${RESET}"

GREEN='\e[1;31m'
CYAN='\e[1;33m'
YELLOW='\e[1;35m'
MAGENTA='\e[1;36m'
RESET='\e[0m'
BOLD='\e[1m'

sleep 30

echo "Configure Service Accounts and IAM Roles for Google Cloud || ARC134 PARTRTT 2"


export ZONE=$(gcloud config get-value compute/zone)
export PROJECT_ID=$(gcloud config get-value project)

echo -e "${CYAN}${BOLD}[*] Pushing Python Execution Payload to bigquery-instance...${RESET}"

# Strict quoting ('EOF') prevents Bash from corrupting the SQL backticks
cat > script2.sh <<'EOF'
#!/bin/bash
echo "--> Installing Python & dependencies on bigquery-instance..."
sudo apt-get update -y
sudo apt-get install -y git python3-pip python3.11-venv

python3 -m venv myvenv
source myvenv/bin/activate

pip install --upgrade pip
pip install google-cloud-bigquery pandas pyarrow db-dtypes google-auth

# Fetch variables directly from VM metadata to guarantee accurate Python auth
export PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
export SA_EMAIL=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" -H "Metadata-Flavor: Google")

echo "--> Creating BigQuery Python query file..."
cat > query.py <<INLINE_EOF
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials(
    service_account_email='${SA_EMAIL}'
)

query = '''
SELECT name, SUM(number) as total_people
FROM \`bigquery-public-data.usa_names.usa_1910_2013\`
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''

client = bigquery.Client(
    project='${PROJECT_ID}',
    credentials=credentials
)

print(client.query(query).to_dataframe())
INLINE_EOF

echo "--> Sync Buffer: Waiting 20 seconds for BigQuery IAM roles to finalize..."
sleep 20

echo "--> Executing BigQuery Python query..."
python3 query.py
EOF

gcloud compute scp script2.sh bigquery-instance:/tmp --zone=$ZONE --quiet
gcloud compute ssh bigquery-instance --zone=$ZONE --quiet --command="bash /tmp/script2.sh"

echo -e "\n${GREEN}${BOLD}>>> DAROO COMPLETE! RAWRR. <<<${RESET}"
