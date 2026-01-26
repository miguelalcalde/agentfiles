#!/bin/bash

# Agentfiles Setup Script
# Creates symlinks to ~/.claude and/or ~/.cursor

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/miguelalcalde/ralphie"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Defaults
DRY_RUN=false
BASE_DIR=""
TOOLS=""

# Show usage
usage() {
    echo "Usage: ./setup.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install     Install symlinks (default)"
    echo "  status      Show current installation status"
    echo "  unlink      Remove symlinks"
    echo "  update      Pull latest changes from git"
    echo "  validate    Check repo structure is valid"
    echo ""
    echo "Options:"
    echo "  --global    Install to home directory (~/.claude, ~/.cursor)"
    echo "  --local     Install to current directory (./.claude, ./.cursor)"
    echo "  --path DIR  Install to custom directory"
    echo "  --dry-run   Preview changes without making them"
    echo "  claude      Install Claude Code only"
    echo "  cursor      Install Cursor only"
    echo "  all         Install both (default)"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh                      # Interactive mode"
    echo "  ./setup.sh --global cursor      # Global install, Cursor only"
    echo "  ./setup.sh --local all          # Local install, both tools"
    echo "  ./setup.sh --dry-run            # Preview only"
    echo "  ./setup.sh status               # Show what's installed"
    echo "  ./setup.sh unlink --global      # Remove global symlinks"
    echo "  ./setup.sh update               # Pull latest changes"
    echo "  ./setup.sh validate             # Check repo structure"
}

# Validate repo structure
validate_repo() {
    local valid=true
    local required_dirs=("agents" "commands" "skills")
    
    echo -e "${CYAN}Validating repo structure...${NC}"
    echo ""
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            local count=$(find "$SCRIPT_DIR/$dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo -e "  ${GREEN}✓${NC} $dir/ ${GRAY}($count files)${NC}"
        else
            echo -e "  ${RED}✗${NC} $dir/ ${RED}(missing)${NC}"
            valid=false
        fi
    done
    
    # Check for git repo
    echo ""
    if [ -d "$SCRIPT_DIR/.git" ]; then
        local branch=$(cd "$SCRIPT_DIR" && git branch --show-current 2>/dev/null || echo "unknown")
        local commit=$(cd "$SCRIPT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} Git repo ${GRAY}($branch @ $commit)${NC}"
    else
        echo -e "  ${YELLOW}!${NC} Not a git repo ${GRAY}(updates won't work)${NC}"
    fi
    
    echo ""
    if [ "$valid" = true ]; then
        echo -e "${GREEN}Repo structure is valid.${NC}"
        return 0
    else
        echo -e "${RED}Repo structure is invalid. Some directories are missing.${NC}"
        return 1
    fi
}

# Update from git
update_repo() {
    echo -e "${CYAN}Updating from git...${NC}"
    echo ""
    
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        echo -e "${RED}Error: Not a git repository.${NC}"
        echo "Clone the repo first: git clone $REPO_URL ~/.agentfiles"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    
    # Show current state
    local before=$(git rev-parse --short HEAD)
    echo -e "  Current: ${GRAY}$before${NC}"
    
    # Pull changes
    if git pull --ff-only; then
        local after=$(git rev-parse --short HEAD)
        if [ "$before" = "$after" ]; then
            echo -e "  ${GREEN}Already up to date.${NC}"
        else
            echo ""
            echo -e "  ${GREEN}Updated: $before → $after${NC}"
            echo ""
            echo "  Recent changes:"
            git log --oneline "$before..$after" | head -5 | while read line; do
                echo -e "    ${GRAY}$line${NC}"
            done
        fi
    else
        echo -e "  ${RED}Update failed. You may have local changes.${NC}"
        echo "  Try: cd $SCRIPT_DIR && git status"
        return 1
    fi
}

# Check if path exists and what type
check_path() {
    local path="$1"
    if [ ! -e "$path" ]; then
        echo "none"
    elif [ -L "$path" ]; then
        echo "symlink"
    elif [ -d "$path" ]; then
        echo "directory"
    elif [ -f "$path" ]; then
        echo "file"
    else
        echo "unknown"
    fi
}

# Create symlink with safety checks
create_link() {
    local source="$1"
    local target="$2"
    local path_type=$(check_path "$target")
    
    # Ensure parent directory exists
    if [ "$DRY_RUN" = true ]; then
        if [ ! -d "$(dirname "$target")" ]; then
            echo -e "  ${BLUE}[dry-run]${NC} Would create directory: $(dirname "$target")"
        fi
    else
        mkdir -p "$(dirname "$target")"
    fi
    
    case "$path_type" in
        none)
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${BLUE}[dry-run]${NC} Would create: $target"
                echo -e "           ${GRAY}-> $source${NC}"
            else
                ln -s "$source" "$target"
                echo -e "  ${GREEN}+${NC} Created: $target"
            fi
            ;;
        symlink)
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${BLUE}[dry-run]${NC} Would update: $target"
                echo -e "           ${GRAY}-> $source${NC}"
            else
                rm "$target"
                ln -s "$source" "$target"
                echo -e "  ${YELLOW}~${NC} Updated: $target"
            fi
            ;;
        directory|file)
            local backup="${target}.backup.$(date +%Y-%m-%d)"
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${RED}[dry-run]${NC} Would backup: $target -> $backup"
                echo -e "  ${BLUE}[dry-run]${NC} Would create: $target"
                echo -e "           ${GRAY}-> $source${NC}"
            else
                echo -e "  ${RED}!${NC} Existing $path_type found: $target"
                read -p "    Backup and replace? [y/N]: " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    mv "$target" "$backup"
                    echo -e "  ${YELLOW}!${NC} Backed up to: $backup"
                    ln -s "$source" "$target"
                    echo -e "  ${GREEN}+${NC} Created: $target"
                else
                    echo -e "  ${GRAY}-${NC} Skipped: $target"
                fi
            fi
            ;;
    esac
}

# Remove symlink (only if it's a symlink)
remove_link() {
    local target="$1"
    local path_type=$(check_path "$target")
    
    case "$path_type" in
        none)
            echo -e "  ${GRAY}-${NC} Not found: $target"
            ;;
        symlink)
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${BLUE}[dry-run]${NC} Would remove: $target"
            else
                rm "$target"
                echo -e "  ${RED}-${NC} Removed: $target"
            fi
            ;;
        *)
            echo -e "  ${YELLOW}!${NC} Skipped (not a symlink): $target"
            ;;
    esac
}

# Show status of a path
show_status() {
    local target="$1"
    local expected_source="$2"
    local path_type=$(check_path "$target")
    local name=$(basename "$target")
    
    case "$path_type" in
        none)
            echo -e "  ${GRAY}○${NC} $name ${GRAY}(not installed)${NC}"
            ;;
        symlink)
            local actual=$(readlink "$target")
            if [ "$actual" = "$expected_source" ]; then
                echo -e "  ${GREEN}●${NC} $name ${GRAY}→ $actual${NC}"
            else
                echo -e "  ${YELLOW}●${NC} $name ${GRAY}→ $actual ${YELLOW}(unexpected)${NC}"
            fi
            ;;
        *)
            echo -e "  ${YELLOW}■${NC} $name ${GRAY}($path_type, not symlink)${NC}"
            ;;
    esac
}

# Setup for a specific tool
setup_tool() {
    local tool="$1"
    local base="$2"
    local tool_dir=$([ "$tool" = "claude" ] && echo ".claude" || echo ".cursor")
    local tool_name=$([ "$tool" = "claude" ] && echo "Claude Code" || echo "Cursor")
    
    echo "$tool_name ($base/$tool_dir):"
    create_link "$SCRIPT_DIR/agents" "$base/$tool_dir/agents"
    create_link "$SCRIPT_DIR/commands" "$base/$tool_dir/commands"
    create_link "$SCRIPT_DIR/skills" "$base/$tool_dir/skills"
    [ "$tool" = "claude" ] && [ -f "$SCRIPT_DIR/settings/claude.json" ] && \
        create_link "$SCRIPT_DIR/settings/claude.json" "$base/$tool_dir/settings.json"
    echo ""
}

# Unlink for a specific tool
unlink_tool() {
    local tool="$1"
    local base="$2"
    local tool_dir=$([ "$tool" = "claude" ] && echo ".claude" || echo ".cursor")
    local tool_name=$([ "$tool" = "claude" ] && echo "Claude Code" || echo "Cursor")
    
    echo "$tool_name ($base/$tool_dir):"
    remove_link "$base/$tool_dir/agents"
    remove_link "$base/$tool_dir/commands"
    remove_link "$base/$tool_dir/skills"
    [ "$tool" = "claude" ] && remove_link "$base/$tool_dir/settings.json"
    echo ""
}

# Status for a specific tool
status_tool() {
    local tool="$1"
    local base="$2"
    local tool_dir=$([ "$tool" = "claude" ] && echo ".claude" || echo ".cursor")
    local tool_name=$([ "$tool" = "claude" ] && echo "Claude Code" || echo "Cursor")
    
    echo "$tool_name ($base/$tool_dir):"
    show_status "$base/$tool_dir/agents" "$SCRIPT_DIR/agents"
    show_status "$base/$tool_dir/commands" "$SCRIPT_DIR/commands"
    show_status "$base/$tool_dir/skills" "$SCRIPT_DIR/skills"
    [ "$tool" = "claude" ] && show_status "$base/$tool_dir/settings.json" "$SCRIPT_DIR/settings/claude.json"
    echo ""
}

# Parse command line arguments
COMMAND="install"
while [ $# -gt 0 ]; do
    case "$1" in
        install|status|unlink|update|validate)
            COMMAND="$1"
            ;;
        --global|-g)
            BASE_DIR="$HOME"
            ;;
        --local|-l)
            BASE_DIR="$(pwd)"
            ;;
        --path|-p)
            shift
            BASE_DIR="$1"
            ;;
        --dry-run|-d)
            DRY_RUN=true
            ;;
        claude|cursor|all)
            TOOLS="$1"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

# Check if running interactively
is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

# Interactive prompts if needed
if [ -z "$BASE_DIR" ] && [ "$COMMAND" != "status" ]; then
    if ! is_interactive; then
        echo -e "${RED}Error: No install location specified.${NC}"
        echo ""
        echo "When running non-interactively, you must specify a location:"
        echo "  ./setup.sh --global all    # Install to home directory"
        echo "  ./setup.sh --local all     # Install to current directory"
        echo ""
        exit 1
    fi
    
    echo -e "${CYAN}Agentfiles Setup${NC}"
    echo ""
    echo "Where do you want to $COMMAND?"
    echo ""
    echo "  1) Global ($HOME) - Available in all projects"
    echo "  2) Local ($(pwd)) - This project only"
    echo "  3) Custom path"
    echo ""
    read -p "Choice [1-3]: " location_choice
    echo ""
    
    case "$location_choice" in
        1) BASE_DIR="$HOME" ;;
        2) BASE_DIR="$(pwd)" ;;
        3)
            read -p "Enter path: " BASE_DIR
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
fi

# Handle standalone commands
if [ "$COMMAND" = "status" ]; then
    echo -e "${CYAN}Agentfiles Status${NC}"
    echo ""
    echo "Global ($HOME):"
    echo ""
    status_tool "claude" "$HOME"
    status_tool "cursor" "$HOME"
    
    if [ "$(pwd)" != "$HOME" ]; then
        echo "Local ($(pwd)):"
        echo ""
        status_tool "claude" "$(pwd)"
        status_tool "cursor" "$(pwd)"
    fi
    exit 0
fi

if [ "$COMMAND" = "update" ]; then
    update_repo
    exit $?
fi

if [ "$COMMAND" = "validate" ]; then
    validate_repo
    exit $?
fi

if [ -z "$TOOLS" ]; then
    if ! is_interactive; then
        echo -e "${RED}Error: No tools specified.${NC}"
        echo ""
        echo "When running non-interactively, you must specify tools:"
        echo "  ./setup.sh --global all      # Both Claude Code and Cursor"
        echo "  ./setup.sh --global claude   # Claude Code only"
        echo "  ./setup.sh --global cursor   # Cursor only"
        echo ""
        exit 1
    fi
    
    echo "Which tools?"
    echo ""
    echo "  1) Claude Code only"
    echo "  2) Cursor only"
    echo "  3) Both"
    echo ""
    read -p "Choice [1-3]: " tools_choice
    echo ""
    
    case "$tools_choice" in
        1) TOOLS="claude" ;;
        2) TOOLS="cursor" ;;
        3) TOOLS="all" ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
fi

# Execute command
case "$COMMAND" in
    install)
        # Validate repo structure first
        for dir in "agents" "commands" "skills"; do
            if [ ! -d "$SCRIPT_DIR/$dir" ]; then
                echo -e "${RED}Error: Required directory '$dir' not found.${NC}"
                echo "Run './setup.sh validate' to check repo structure."
                exit 1
            fi
        done
        
        [ "$DRY_RUN" = true ] && echo -e "${BLUE}Dry run mode - no changes will be made${NC}\n"
        
        if [ "$TOOLS" = "claude" ] || [ "$TOOLS" = "all" ]; then
            setup_tool "claude" "$BASE_DIR"
        fi
        if [ "$TOOLS" = "cursor" ] || [ "$TOOLS" = "all" ]; then
            setup_tool "cursor" "$BASE_DIR"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}Dry run complete. No changes were made.${NC}"
        else
            echo -e "${GREEN}Done!${NC}"
            echo ""
            echo -e "${GRAY}Tip: Run './setup.sh update' to get the latest changes.${NC}"
        fi
        ;;
    unlink)
        [ "$DRY_RUN" = true ] && echo -e "${BLUE}Dry run mode - no changes will be made${NC}\n"
        
        if [ "$TOOLS" = "claude" ] || [ "$TOOLS" = "all" ]; then
            unlink_tool "claude" "$BASE_DIR"
        fi
        if [ "$TOOLS" = "cursor" ] || [ "$TOOLS" = "all" ]; then
            unlink_tool "cursor" "$BASE_DIR"
        fi
        
        [ "$DRY_RUN" = true ] && echo -e "${BLUE}Dry run complete. No changes were made.${NC}" || echo -e "${GREEN}Done!${NC}"
        ;;
esac
