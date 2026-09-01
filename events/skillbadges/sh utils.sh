#!/bin/bash

# --- Define Colors ---
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
WHITE='\033[97m'
NC='\033[0m' # No Color

# --- Helper Functions ---
print_info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1"
}

print_banner() {
    clear
    echo "Terus Semangat, Semoga digaji Dolar, Euro, Riyal"
}

check_command() {
    if ! command -v "$1" > /dev/null 2>&1; then
        error "Command '$1' could not be found. Please install it."
        exit 1
    fi
}

check_login() {
    print_info "Verifying gcloud authentication..."
    if ! gcloud auth print-access-token > /dev/null 2>&1; then
        error "You are not authenticated with gcloud."
        echo "Run: gcloud auth login"
        exit 1
    fi
    success "Authenticated successfully."
}