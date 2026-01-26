#!/bin/bash

# Remote installer for Agentfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/miguelalcalde/ralphie/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

REPO_URL="https://github.com/miguelalcalde/ralphie.git"
INSTALL_DIR="$HOME/.agentfiles"

echo -e "${CYAN}Agentfiles Installer${NC}"
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is required but not installed.${NC}"
    exit 1
fi

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Agentfiles already installed at $INSTALL_DIR${NC}"
    echo ""
    read -p "Update existing installation? [Y/n]: " update_choice
    if [ "$update_choice" = "n" ] || [ "$update_choice" = "N" ]; then
        echo "Aborted."
        exit 0
    fi
    
    echo ""
    echo -e "Updating..."
    cd "$INSTALL_DIR"
    git pull --ff-only
    echo ""
    echo -e "${GREEN}Updated!${NC}"
else
    echo -e "Cloning to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    echo ""
    echo -e "${GREEN}Cloned!${NC}"
fi

echo ""

# Run setup
echo -e "Running setup..."
echo ""
cd "$INSTALL_DIR"
./setup.sh

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Commands:"
echo -e "  ${GRAY}cd $INSTALL_DIR && ./setup.sh status${NC}    # Check status"
echo -e "  ${GRAY}cd $INSTALL_DIR && ./setup.sh update${NC}    # Update"
echo -e "  ${GRAY}cd $INSTALL_DIR && ./setup.sh unlink${NC}    # Uninstall"
