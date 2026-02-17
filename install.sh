#!/bin/bash

# Bootstrap-only installer.
# All installation logic lives in setup.sh.

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

REPO_URL="https://github.com/miguelalcalde/agentfiles.git"
INSTALL_DIR="$HOME/.agentfiles"

echo -e "${CYAN}Agentfiles bootstrap${NC}"
echo -e "Repo location: ${GRAY}$INSTALL_DIR${NC}"
echo ""

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is required but not installed.${NC}"
    exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Existing installation found.${NC} Updating..."
    (cd "$INSTALL_DIR" && git pull --ff-only) || true
else
    echo "Cloning..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

echo ""
cd "$INSTALL_DIR"
echo -e "${CYAN}Launching setup CLI...${NC}"
echo -e "${GRAY}(Arguments passed to install.sh are forwarded to setup.sh)${NC}"
echo ""
exec ./setup.sh "$@"
