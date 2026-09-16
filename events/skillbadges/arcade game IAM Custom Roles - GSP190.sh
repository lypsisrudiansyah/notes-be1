

#!/bin/bash

clear
echo "IAM Custom Roles - GSP190"


BLACK=$(tput setaf 240)       # Muted Medium Grey / Charcoal (readable on dark terminals)
RED=$(tput setaf 196)         # Electric Scarlet / Neon Crimson
GREEN=$(tput setaf 48)        # Mint / Bright Spring Green
YELLOW=$(tput setaf 214)      # Warm Sunset / Golden Orange
BLUE=$(tput setaf 75)         # Cornflower / Soft Sky Blue
MAGENTA=$(tput setaf 199)     # Hot Neon Magenta / Deep Pink
CYAN=$(tput setaf 51)         # Bright Electric Aqua / Light Cyan
WHITE=$(tput setaf 255)       # Crisp Titanium High-Intensity White

# --- Background 256-Color Palette Remapping ---
BG_BLACK=$(tput setab 234)    # Deep Jet / Dark Slate (high contrast for status bars)
BG_RED=$(tput setab 124)      # Deep Brick / Dark Crimson
BG_GREEN=$(tput setab 28)     # Forest / Dark Emerald
BG_YELLOW=$(tput setab 178)   # Deep Ochre / Amber
BG_BLUE=$(tput setab 24)      # Deep Midnight / Navy Blue
BG_MAGENTA=$(tput setab 89)   # Deep Plum / Dark Velvet Magenta
BG_CYAN=$(tput setab 30)      # Deep Teal / Petroleum Blue
BG_WHITE=$(tput setab 250)    # Soft Platinum / Off-White

# --- Formatting Attributes ---
BOLD=$(tput bold)
RESET=$(tput sgr0)
#----------------------------------------------------start--------------------------------------------------#

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

echo 'title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete' > role-definition.yaml

gcloud iam roles create editor --project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml

gcloud iam roles create viewer --project $DEVSHELL_PROJECT_ID \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA

echo 'description: Edit access for App Versions
etag:
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/'$DEVSHELL_PROJECT_ID'/roles/editor
stage: ALPHA
title: Role Editor' > new-role-definition.yaml

gcloud iam roles update editor --project $DEVSHELL_PROJECT_ID \
--file new-role-definition.yaml --quiet

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--add-permissions storage.buckets.get,storage.buckets.list

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--stage DISABLED

gcloud iam roles delete viewer --project $DEVSHELL_PROJECT_ID

gcloud iam roles undelete viewer --project $DEVSHELL_PROJECT_ID

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "hore"