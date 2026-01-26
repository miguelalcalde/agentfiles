#!/bin/bash

# Portable Agents Setup Script
# Creates symlinks from ~/.agents to ~/.claude and/or ~/.cursor

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to create symlink with backup
create_link() {
    local source="$1"
    local target="$2"
    
    mkdir -p "$(dirname "$target")"
    
    if [ -L "$target" ]; then
        rm "$target"
        ln -s "$source" "$target"
        echo -e "  ${YELLOW}~${NC} Updated: $target"
    elif [ -e "$target" ]; then
        mv "$target" "${target}.backup"
        ln -s "$source" "$target"
        echo -e "  ${YELLOW}!${NC} Backed up existing to ${target}.backup"
        echo -e "  ${GREEN}+${NC} Created: $target"
    else
        ln -s "$source" "$target"
        echo -e "  ${GREEN}+${NC} Created: $target"
    fi
}

setup_claude() {
    echo "Claude Code (~/.claude):"
    create_link "$SCRIPT_DIR/agents" "$HOME/.claude/agents"
    create_link "$SCRIPT_DIR/commands" "$HOME/.claude/commands"
    create_link "$SCRIPT_DIR/skills" "$HOME/.claude/skills"
    [ -f "$SCRIPT_DIR/settings/claude.json" ] && create_link "$SCRIPT_DIR/settings/claude.json" "$HOME/.claude/settings.json"
    echo ""
}

setup_cursor() {
    echo "Cursor (~/.cursor):"
    create_link "$SCRIPT_DIR/agents" "$HOME/.cursor/agents"
    create_link "$SCRIPT_DIR/commands" "$HOME/.cursor/commands"
    create_link "$SCRIPT_DIR/skills" "$HOME/.cursor/skills"
    echo ""
}

# Check for command line argument
if [ -n "$1" ]; then
    case "$1" in
        claude)
            setup_claude
            ;;
        cursor)
            setup_cursor
            ;;
        all)
            setup_claude
            setup_cursor
            ;;
        *)
            echo "Usage: ./setup.sh [claude|cursor|all]"
            exit 1
            ;;
    esac
    echo -e "${GREEN}Done!${NC}"
    exit 0
fi

# Interactive menu
echo -e "${CYAN}Portable Agents Setup${NC}"
echo ""
echo "Where do you want to install?"
echo ""
echo "  1) Claude Code only"
echo "  2) Cursor only"
echo "  3) Both"
echo ""
read -p "Choice [1-3]: " choice

echo ""

case "$choice" in
    1)
        setup_claude
        ;;
    2)
        setup_cursor
        ;;
    3)
        setup_claude
        setup_cursor
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo -e "${GREEN}Done!${NC}"
