

#!/bin/bash

clear
echo "Spanner - Defining Schemas and Understanding Query Plans - GSP1050"


BOLD=$(tput bold)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)

# Text Colors (Vibrant 256-Color Palette)
BLACK=$(tput setaf 235)      # Charcoal / Dark Grey
RED=$(tput setaf 196)        # Laser Red
GREEN=$(tput setaf 46)       # Neon Mint Green
YELLOW=$(tput setaf 226)     # Electric Pure Yellow
BLUE=$(tput setaf 39)        # Vivid Sky Blue
MAGENTA=$(tput setaf 201)    # Hot Neon Magenta
CYAN=$(tput setaf 51)        # Electric Aqua Cyan
WHITE=$(tput setaf 231)      # Ultra-Bright Pure White

# Background Colors (Deep Contrast Palette)
BG_RED=$(tput setab 160)     # Deep Crimson
BG_GREEN=$(tput setab 28)    # Rich Forest Green
BG_YELLOW=$(tput setab 214)  # Deep Amber Yellow
BG_BLUE=$(tput setab 21)     # Deep Royal Blue
BG_MAGENTA=$(tput setab 127) # Deep Plum Magenta


#  DB DATABASE OPERATIONS
echo "${MAGENTA}${BOLD}💼 STEP 1: Setting Up Portfolios...${RESET}"
declare -A PORTFOLIOS=(
    [1]="Banking,Bnkg,All Banking Business"
    [2]="Asset Growth,AsstGrwth,All Asset Focused Products"
    [3]="Insurance,Ins,All Insurance Focused Products"
)

for id in "${!PORTFOLIOS[@]}"; do
    IFS=',' read -r name short info <<< "${PORTFOLIOS[$id]}"
    echo "${WHITE}Creating portfolio: ${YELLOW}$name${RESET}"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES ($id, '$name', '$short', '$info')"
done
echo "${GREEN}${BOLD}✔ Portfolios created successfully${RESET}"
echo ""

# ======================
#  CATEGORY SETUP
# ======================
echo "${MAGENTA}${BOLD}🗂️ STEP 2: Creating Product Categories...${RESET}"
declare -A CATEGORIES=(
    [1]="1,Cash"
    [2]="2,Investments - Short Return"
    [3]="2,Annuities"
    [4]="3,Life Insurance"
)

for id in "${!CATEGORIES[@]}"; do
    IFS=',' read -r portfolio_id name <<< "${CATEGORIES[$id]}"
    echo "${WHITE}Creating category: ${YELLOW}$name${RESET}"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES ($id, $portfolio_id, '$name')"
done
echo "${GREEN}${BOLD}✔ Categories created successfully${RESET}"
echo ""

# ======================
#  PRODUCT SETUP
# ======================
echo "${MAGENTA}${BOLD}🛒 STEP 3: Adding Financial Products...${RESET}"
declare -A PRODUCTS=(
    [1]="1,1,Checking Account,ChkAcct,Banking LOB"
    [2]="2,2,Mutual Fund Consumer Goods,MFundCG,Investment LOB"
    [3]="3,2,Annuity Early Retirement,AnnuFixed,Investment LOB"
    [4]="4,3,Term Life Insurance,TermLife,Insurance LOB"
    [5]="1,1,Savings Account,SavAcct,Banking LOB"
    [6]="1,1,Personal Loan,PersLn,Banking LOB"
    [7]="1,1,Auto Loan,AutLn,Banking LOB"
    [8]="4,3,Permanent Life Insurance,PermLife,Insurance LOB"
    [9]="2,2,US Savings Bonds,USSavBond,Investment LOB"
)

for id in "${!PRODUCTS[@]}"; do
    IFS=',' read -r category_id portfolio_id name code class <<< "${PRODUCTS[$id]}"
    echo "${WHITE}Adding product: ${YELLOW}$name${RESET}"
    gcloud spanner databases execute-sql banking-ops-db \
        --instance=banking-ops-instance \
        --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES ($id, $category_id, $portfolio_id, '$name', '$code', '$class')"
done
echo "${GREEN}${BOLD}✔ Financial products added successfully${RESET}"
echo ""

# ======================
#  PYTHON HELPER SCRIPTS
# ======================
echo "${MAGENTA}${BOLD}🐍 STEP 4: Running Python Helper Scripts...${RESET}"
echo "${WHITE}Setting up Python environment...${RESET}"
mkdir -p python-helper && cd python-helper || {
    echo "${RED}${BOLD}❌ Failed to create python-helper directory${RESET}"
    exit 1
}

wget -q https://storage.googleapis.com/cloud-training/OCBL373/requirements.txt
wget -q https://storage.googleapis.com/cloud-training/OCBL373/snippets.py

pip install -q -r requirements.txt
pip install -q setuptools

echo "${WHITE}Executing database operations...${RESET}"
declare -a PYTHON_COMMANDS=(
    "insert_data"
    "query_data"
    "add_column"
    "update_data"
    "query_data_with_new_column"
    "add_index"
)

for command in "${PYTHON_COMMANDS[@]}"; do
    echo "${WHITE}Running: ${YELLOW}$command${RESET}"
    python snippets.py banking-ops-instance --database-id banking-ops-db $command
done
echo "${GREEN}${BOLD}✔ Python sa operations completed successfully${RESET}"
echo ""

echo "DOONNEE"