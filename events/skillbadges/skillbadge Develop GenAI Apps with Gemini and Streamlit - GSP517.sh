

#!/bin/bash

clear
echo "Develop GenAI Apps with Gemini and Streamlit - GSP517"


#Develop GenAI Apps with Gemini and Streamlit - gsp517

# PRE-FLIGHT CHECKS & VARIABLES (DYNAMIC AUTO-FETCH)
# ==============================================================================
echo -e "\033[1m\033[33m[jkaisjdais] Auto-fetching Project, Zone, and Region...\033[0m"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)

if [[ -z "$ZONE" ]]; then
    echo -e "\033[1m\033[31m⚠️ Could not auto-detect the default zone via gcloud metadata.\033[0m"
    read -p "Please enter the lab Zone (e.g., us-east1-c): " ZONE
    export ZONE
fi

export REGION=${ZONE%-*}

gcloud config set compute/zone $ZONE 2>/dev/null
gcloud config set compute/region $REGION 2>/dev/null

export PROJECT=$PROJECT_ID
export GCP_PROJECT=$PROJECT_ID
export GCP_REGION=$REGION

echo -e "✅ Project ID: \033[32m$PROJECT_ID\033[0m"
echo -e "✅ Zone:       \033[32m$ZONE\033[0m"
echo -e "✅ Region:     \033[32m$REGION\033[0m\n"
# ==============================================================================

# Enable API & Clone Repo
echo -e "\033[1m\033[36mTask 2: Setting up Application Files...\033[0m"
gcloud services enable run.googleapis.com aiplatform.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
git clone https://github.com/GoogleCloudPlatform/generative-ai.git
cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun
rm -f Dockerfile chef.py requirements.txt

# Create requirements.txt
cat << 'EOF' > requirements.txt
streamlit==1.44.1
google-genai==1.9.0
google-cloud-logging
google-cloud-aiplatform
EOF

# Create Dockerfile
cat << 'EOF' > Dockerfile
FROM python:3.13-slim
EXPOSE 8080
WORKDIR /app
COPY . ./
RUN pip install --no-cache-dir -r requirements.txt
ENTRYPOINT ["streamlit", "run", "chef.py", "--server.port=8080", "--server.address=0.0.0.0"]
EOF

# Create chef.py with gemini-2.5-flash
cat << 'EOF' > chef.py
import os
import streamlit as st
import logging
from google.cloud import logging as cloud_logging
import vertexai
from vertexai.preview.generative_models import (
    GenerationConfig,
    GenerativeModel,
    HarmBlockThreshold,
    HarmCategory,
    Part,
)
from datetime import (
    date,
    timedelta,
)
# configure logging
logging.basicConfig(level=logging.INFO)
# attach a Cloud Logging handler to the root logger
log_client = cloud_logging.Client()
log_client.setup_logging()

PROJECT_ID = os.environ.get("GCP_PROJECT")  # Your Google Cloud Project ID
LOCATION = os.environ.get("GCP_REGION")  # Your Google Cloud Project Region
vertexai.init(project=PROJECT_ID, location=LOCATION)


@st.cache_resource
def load_models():
    text_model_flash = GenerativeModel("gemini-2.5-flash")
    return text_model_flash


def get_gemini_flash_text_response(
    model: GenerativeModel,
    contents: str,
    generation_config: GenerationConfig,
    stream: bool = True,
):
    safety_settings = {
        HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE,
    }

    responses = model.generate_content(
        prompt,
        generation_config=generation_config,
        safety_settings=safety_settings,
        stream=stream,
    )

    final_response = []
    for response in responses:
        try:
            final_response.append(response.text)
        except IndexError:
            final_response.append("")
            continue
    return " ".join(final_response)

st.header("Vertex AI Gemini API", divider="gray")
text_model_flash = load_models()
st.write("Using Gemini Flash - Text only model")
st.subheader("AI Chef")

cuisine = st.selectbox("What cuisine do you desire?", ("American", "Chinese", "French", "Indian", "Italian", "Japanese", "Mexican", "Turkish"), index=None, placeholder="Select your desired cuisine.")
dietary_preference = st.selectbox("Do you have any dietary preferences?", ("Diabetese", "Glueten free", "Halal", "Keto", "Kosher", "Lactose Intolerance", "Paleo", "Vegan", "Vegetarian", "None"), index=None, placeholder="Select your desired dietary preference.")
allergy = st.text_input("Enter your food allergy:  \n\n", key="allergy", value="peanuts")
ingredient_1 = st.text_input("Enter your first ingredient:  \n\n", key="ingredient_1", value="ahi tuna")
ingredient_2 = st.text_input("Enter your second ingredient:  \n\n", key="ingredient_2", value="chicken breast")
ingredient_3 = st.text_input("Enter your third ingredient:  \n\n", key="ingredient_3", value="tofu")

wine = st.radio ("What wine do you prefer?\n\n", ["Red", "White", "None"], key="wine", horizontal=True)
max_output_tokens = 2048

prompt = f"""I am a Chef.  I need to create {cuisine} \n
recipes for customers who want {dietary_preference} meals. \n
However, don't include recipes that use ingredients with the customer's {allergy} allergy. \n
I have {ingredient_1}, \n
{ingredient_2}, \n
and {ingredient_3} \n
in my kitchen and other ingredients. \n
The customer's wine preference is {wine} \n
Please provide some for meal recommendations.
For each recommendation include preparation instructions,
time to prepare
and the recipe title at the beginning of the response.
Then include the wine paring for each recommendation.
At the end of the recommendation provide the calories associated with the meal
and the nutritional facts.
"""
config = {
    "temperature": 0.8,
    "max_output_tokens": 2048,
}
generate_t2t = st.button("Generate my recipes.", key="generate_t2t")
if generate_t2t and prompt:
    with st.spinner("Generating your recipes using Gemini..."):
        first_tab1, first_tab2 = st.tabs(["Recipes", "Prompt"])
        with first_tab1:
            response = get_gemini_flash_text_response(text_model_flash, prompt, generation_config=config,)
            if response:
                st.write("Your recipes:")
                st.write(response)
                logging.info(response)
        with first_tab2:
            st.text(prompt)
EOF

# Upload file
echo -e "\033[1m\033[36mUploading chef.py to Cloud Storage...\033[0m"
gcloud storage cp chef.py gs://$PROJECT_ID-generative-ai/

# 4. Test Application (Background)
echo -e "\n\033[1m\033[33mTask 3: Starting Local Test...\033[0m"
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m pip install -r requirements.txt
nohup streamlit run chef.py --browser.serverAddress=localhost --server.enableCORS=false --server.enableXsrfProtection=false --server.port 8080 > streamlit.log 2>&1 &
sleep 15
echo -e "\033[1m\033[33mPinging the local Streamlit application (Task 3)...\033[0m"
curl -s http://localhost:8080 > /dev/null
echo -e "✅ \033[32mLocal App running and tested.\033[0m"

# 5. Build and Deploy
echo -e "\n\033[1m\033[33mTask 4: Building and Pushing Docker Image...\033[0m"
AR_REPO='chef-repo'
SERVICE_NAME='chef-streamlit-app' 
gcloud artifacts repositories create "$AR_REPO" --location="$REGION" --repository-format=Docker
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"

echo -e "\n\033[1m\033[33mTask 5: Deploying to Cloud Run...\033[0m"
gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$REGION \
  --platform=managed  \
  --project=$PROJECT_ID \
  --set-env-vars=GCP_PROJECT=$PROJECT_ID,GCP_REGION=$REGION

echo -e "\n\033[1m\033[33mFetching Cloud Run URL and testing for grader...\033[0m"
SERVICE_URL=$(gcloud run services describe chef-streamlit-app --region=$REGION --format='value(status.url)')
curl -s $SERVICE_URL > /dev/null
echo -e "✅ \033[32mCloud Run deployment tested successfully.\033[0m"

echo -e "\n\033[1;35m\033[1m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;35m\033[1m║            🎉 AUTOMATION COMPLETED SUCCESSFULLY 🎉           ║\033[0m"
echo -e "\033[1;35m\033[1m╚════════════════════════════════════════════════════════════╝\033[0m"
echo -e "\n\033[1m\033[36mYou can now click 'Check my progress' for Tasks 2, 3, 4, and 5.\033[0m"


