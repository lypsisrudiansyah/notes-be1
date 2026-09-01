

#!/bin/bash

clear
echo "Cloud Spanner - Database Fundamentals - GSP1048"


# Foreground Colors (Vibrant 256-Color Palette)
BLACK=`tput setaf 235`       # Deep Charcoal
RED=`tput setaf 196`         # Bright Crimson / Neon Red
GREEN=`tput setaf 46`        # Electric Spring Green
YELLOW=`tput setaf 226`      # Pure Vibrant Yellow
BLUE=`tput setaf 39`         # Deep Sky Blue
MAGENTA=`tput setaf 201`     # Hot Neon Magenta
CYAN=`tput setaf 51`         # Vivid Aqua / Cyan
WHITE=`tput setaf 231`       # Ultra Pure White

# Background Colors (Matching 256-Color Palette)
BG_BLACK=`tput setab 234`    # Soft Dark Background
BG_RED=`tput setab 160`      # Ruby Red Background
BG_GREEN=`tput setab 28`     # Forest Green Background
BG_YELLOW=`tput setab 220`   # Warm Amber Background
BG_BLUE=`tput setab 27`      # Royal Blue Background
BG_MAGENTA=`tput setab 163`  # Deep Magenta Background
BG_CYAN=`tput setab 37`      # Teal / Dark Cyan Background
BG_WHITE=`tput setab 255`    # Crisp White Background

# Styles
BOLD=`tput bold`
RESET=`tput sgr0`

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

gcloud spanner instances create banking-instance \
--config=regional-$REGION  \
--description="awesome" \
--nodes=1

gcloud spanner databases create banking-db --instance=banking-instance

gcloud spanner instances create banking-instance-2 \
--config=regional-$REGION  \
--description="awesome" \
--nodes=2

gcloud spanner databases create banking-db-2 --instance=banking-instance-2

gcloud spanner databases ddl update banking-db --instance=banking-instance --ddl="CREATE TABLE Customer (
  CustomerId STRING(36) NOT NULL,
  Name STRING(MAX) NOT NULL,
  Location STRING(MAX) NOT NULL,
) PRIMARY KEY (CustomerId);"

echo "${BG_RED}${BOLD}Keep Learning !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#