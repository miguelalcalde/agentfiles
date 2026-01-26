#!/bin/bash

# Remote installer for Agentfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/miguelalcalde/ralphie/main/install.sh | bash
#
# This script installs globally to ~/.agentfiles and sets up for all tools.
# For local (per-project) install, clone the repo and run: ./setup.sh --local

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

REPO_URL="https://github.com/miguelalcalde/agentfiles.git"
INSTALL_DIR="$HOME/.agentfiles"

echo -e "${CYAN}Agentfiles Installer${NC}"
echo ""
echo -e "This will install agentfiles globally to ${GRAY}$INSTALL_DIR${NC}"
echo -e "For per-project install, clone the repo and run: ${GRAY}./setup.sh --local${NC}"
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is required but not installed.${NC}"
    exit 1
fi

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Existing installation found.${NC} Updating..."
    echo ""
    cd "$INSTALL_DIR"
    
    before=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    if git pull --ff-only; then
        after=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        if [ "$before" = "$after" ]; then
            echo -e "${GREEN}Already up to date.${NC}"
        else
            echo -e "${GREEN}Updated: $before → $after${NC}"
        fi
    else
        echo -e "${YELLOW}Update failed (you may have local changes).${NC}"
    fi
else
    echo -e "Cloning..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    echo -e "${GREEN}Cloned to $INSTALL_DIR${NC}"
fi

echo ""

# Run setup non-interactively (global, all tools)
echo -e "Setting up symlinks..."
cd "$INSTALL_DIR"
./setup.sh --global all

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo -e "  ${GRAY}./setup.sh status${NC}              # Check what's installed"
echo -e "  ${GRAY}./setup.sh update${NC}              # Pull latest changes"
echo -e "  ${GRAY}./setup.sh --local all${NC}         # Install to current project"
echo -e "  ${GRAY}./setup.sh unlink --global${NC}     # Remove global install"
echo ""
echo -e "Run commands from: ${GRAY}cd $INSTALL_DIR${NC}"
