

#!/bin/bash

clear
echo "Develop GenAI Apps with Gemini and Streamlit - GSP517"


# 1. Navigate to the correct directory
cd ~/generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

# 2. Kill any hidden background streamlit processes that might be blocking the port
pkill -f streamlit
sleep 2

# 3. Set the EXACT environment variables in the active shell
export PROJECT=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export GCP_PROJECT=$PROJECT
export GCP_REGION=$REGION

# 4. Activate the virtual environment
source gemini-streamlit/bin/activate

# 5. Run the Streamlit server in the FOREGROUND
streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080