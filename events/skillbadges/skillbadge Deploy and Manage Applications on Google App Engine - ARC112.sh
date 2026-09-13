#!/bin/bash
clear
echo "Deploy and Manage Applications on Google App Engine - ARC112"

# GCP Shell

gcloud app create --region=us-central --quiet

# VM Instance SSH Terminal

# 1. Ensure clean workspace and navigate to the target directory
cd ~
[ ! -d "python-docs-samples" ] && git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd ~/python-docs-samples/appengine/standard_python3/hello_world

# 2. Reset local changes and add scaling limit
git checkout app.yaml main.py 2>/dev/null || true
echo "" >> app.yaml
echo "automatic_scaling:" >> app.yaml
echo "  max_instances: 1" >> app.yaml

# 3. Initialize App Engine in us-central (ignore error if already created)
gcloud app create --region=us-central --quiet || true

# 4. Deploy Task 2
gcloud app deploy --quiet

# 5. Check progress for Task 1 and Task 2 now, then update greeting for Task 3
sed -i 's/Hello World!/Goodbye world!/g' main.py

# 6. Redeploy over current version to preserve instance limits
CURRENT_VERSION=$(gcloud app versions list --hide-no-traffic --format="value(version.id)" | head -n 1)
gcloud app deploy --version="$CURRENT_VERSION" --quiet

echo "Done! Ready to check all progress items."