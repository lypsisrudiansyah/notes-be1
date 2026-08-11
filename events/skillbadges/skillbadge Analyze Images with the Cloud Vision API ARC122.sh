

#!/bin/bash

clear
echo "Analyze Images with the Cloud Vision API || ARC122"

GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
RED='\e[1;31m'
RESET='\e[0m'
BOLD='\e[1m'

echo -e "${RESET}"
echo -e "${MAGENTA}${BOLD}>>> jangkreaskdoa: ARC122 TERMINAL AUTOMATION INITIALIZED <<<${RESET}\n"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
echo -e "${YELLOW}${BOLD}[*] Project ID: ${PROJECT_ID}${RESET}\n"

echo -e "${CYAN}${BOLD}[*] Auto-generating restricted API Key via CLI...${RESET}"
gcloud services enable apikeys.googleapis.com vision.googleapis.com --quiet
sleep 5

gcloud services api-keys create \
    --display-name="Manjar" \
    --api-target=service=vision.googleapis.com \
    --quiet 2>/dev/null
sleep 5

export API_KEY=$(gcloud services api-keys get-key-string \
    $(gcloud services api-keys list --filter="display_name='Manjar'" --format="value(name)" | head -n 1) \
    --format="value(keyString)" 2>/dev/null)

if [ -z "$API_KEY" ]; then
    echo -e "\n${RED}${BOLD}[!] Auto-generation blocked by Qwiklabs. Please create the API key manually in the UI (APIs & Services > Credentials) and enter it below:${RESET}"
    read -p "Enter API Key: " API_KEY
else
    echo -e "${GREEN}${BOLD}[*] API Key successfully generated: ${API_KEY}${RESET}\n"
fi

echo -e "${BLUE}${BOLD}[jangkreaskdoa] Task 1: Setting public read access on the bucket image...${RESET}"
gsutil acl ch -u allUsers:R gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg > /dev/null 2>&1

echo -e "${MAGENTA}${BOLD}[jangkreaskdoa] Task 2 & 3: Building TEXT_DETECTION JSON payload...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

echo -e "${CYAN}${BOLD}[jangkreaskdoa] Task 3: Hitting Vision API for Text Detection...${RESET}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json "https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o text-response.json
gsutil cp text-response.json gs://$PROJECT_ID-bucket > /dev/null 2>&1

echo -e "${YELLOW}${BOLD}[jangkreaskdoa] Task 3: Re-building JSON for LANDMARK_DETECTION...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LANDMARK_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

echo -e "${BLUE}${BOLD}[jangkreaskdoa] Task 3: Hitting Vision API for Landmark Detection...${RESET}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json "https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o landmark-response.json
gsutil cp landmark-response.json gs://$PROJECT_ID-bucket > /dev/null 2>&1

# rm request.json text-response.json landmark-response.json 2>/dev/null

echo -e "\n${GREEN}${BOLD}>>> MISSION COMPLETE! Check all progress bars in Qwiklabs. <<<${RESET}"