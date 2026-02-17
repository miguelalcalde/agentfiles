#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/miguelalcalde/agentfiles.git"
INSTALL_DIR="$HOME/.agentfiles"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

COMMAND="install"
BASE_DIR=""
TOOLS=""
MODE=""
DRY_RUN=false

AGENTS_REQUESTED=false
FILES_REQUESTED=false
SKILLS_REQUESTED=false
COMMANDS_REQUESTED=false
AGENTS_ARG=""
FILES_ARG=""
SKILLS_ARG=""
COMMANDS_ARG=""

DEFAULT_FILES=("commands" "skills")
AVAILABLE_FILE_GROUPS=("commands" "skills" "backlog")

ensure_repo_checkout() {
    if [ -d "$SCRIPT_DIR/agents" ] && [ -d "$SCRIPT_DIR/commands" ] && [ -d "$SCRIPT_DIR/skills" ]; then
        return
    fi

    echo -e "${CYAN}Agentfiles bootstrap${NC}"
    echo -e "Installing to ${GRAY}$INSTALL_DIR${NC}"
    echo ""

    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is required but not installed.${NC}"
        exit 1
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${YELLOW}Existing installation found.${NC} Updating..."
        (cd "$INSTALL_DIR" && git pull --ff-only) || true
    else
        echo "Cloning..."
        git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    fi

    echo ""
    exec "$INSTALL_DIR/setup.sh" "$@"
}

usage() {
    echo "Usage: ./setup.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install        Install selected agents/files (default)"
    echo "  status         Show current installation status"
    echo "  update         Pull latest changes from git"
    echo ""
    echo "Install flags:"
    echo "  --agents [x,y] Install agent files (prompt if omitted)"
    echo "  --skills [x,y] Install skills (prompt if omitted)"
    echo "  --commands [x,y] Install commands (prompt if omitted)"
    echo "  --files [x,y]  Install file groups: commands, skills, backlog"
    echo ""
    echo "Scope and mode:"
    echo "  --global       Install to home directory (~)"
    echo "  --local        Install to current project directory"
    echo "  --path DIR     Install to custom base directory"
    echo "  --mode MODE    Install mode: symlink | copy"
    echo "  --tools TOOLS  claude | cursor | all"
    echo "  --dry-run      Preview changes without writing"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh"
    echo "  ./setup.sh --agents"
    echo "  ./setup.sh --skills"
    echo "  ./setup.sh --commands"
    echo "  ./setup.sh --agents picker,planner --mode symlink --global --tools all"
    echo "  ./setup.sh --skills feature-workflow,code-review --mode symlink --global --tools all"
    echo "  ./setup.sh --commands pick,plan --mode symlink --global --tools all"
    echo "  ./setup.sh --files commands,skills --mode symlink --global"
    echo "  ./setup.sh --files backlog --mode copy --local"
}

is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

split_csv() {
    local input="$1"
    input="${input// /}"
    IFS=',' read -r -a OUT_ARRAY <<< "$input"
}

relative_path() {
    local source="$1"
    local target_dir="$2"
    python3 -c "import os,sys;print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$source" "$target_dir"
}

path_type() {
    local path="$1"
    if [ -L "$path" ]; then
        echo "symlink"
    elif [ -d "$path" ]; then
        echo "directory"
    elif [ -f "$path" ]; then
        echo "file"
    else
        echo "none"
    fi
}

confirm_replace() {
    local target="$1"
    if ! is_interactive; then
        echo "no"
        return
    fi
    read -p "Replace existing path '$target'? [y/N]: " reply
    if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
        echo "yes"
    else
        echo "no"
    fi
}

install_entry() {
    local source="$1"
    local target="$2"
    local mode="$3"
    local source_type="$4"
    local current_type
    current_type=$(path_type "$target")

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} $mode $source -> $target"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ "$current_type" != "none" ]; then
        local decision
        decision=$(confirm_replace "$target")
        if [ "$decision" != "yes" ]; then
            echo -e "  ${GRAY}-${NC} Skipped: $target"
            return
        fi
        local backup="${target}.backup.$(date +%Y-%m-%d-%H%M%S)"
        mv "$target" "$backup"
        echo -e "  ${YELLOW}!${NC} Backed up: $backup"
    fi

    if [ "$mode" = "copy" ]; then
        if [ "$source_type" = "dir" ]; then
            cp -R "$source" "$target"
        else
            cp "$source" "$target"
        fi
        echo -e "  ${GREEN}+${NC} Copied: $target"
        return
    fi

    local rel
    rel=$(relative_path "$source" "$(dirname "$target")")
    ln -s "$rel" "$target"
    echo -e "  ${GREEN}+${NC} Linked: $target ${GRAY}-> $rel${NC}"
}

tool_dir_name() {
    local tool="$1"
    if [ "$tool" = "claude" ]; then
        echo ".claude"
    else
        echo ".cursor"
    fi
}

install_agents_for_tool() {
    local tool="$1"
    shift
    local selected_agents=("$@")
    local tool_dir
    tool_dir="$(tool_dir_name "$tool")"
    local target_agents_dir="$BASE_DIR/$tool_dir/agents"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$target_agents_dir"
    fi
    echo "$tool agent files:"
    for agent in "${selected_agents[@]}"; do
        local source="$SCRIPT_DIR/agents/$agent.md"
        local target="$target_agents_dir/$agent.md"
        if [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Agent not found: $agent"
            continue
        fi
        install_entry "$source" "$target" "$MODE" "file"
    done
}

install_file_group_for_tool() {
    local tool="$1"
    local group="$2"
    local tool_dir
    tool_dir="$(tool_dir_name "$tool")"

    if [ "$group" = "commands" ] || [ "$group" = "skills" ]; then
        install_entry "$SCRIPT_DIR/$group" "$BASE_DIR/$tool_dir/$group" "$MODE" "dir"
    fi
}

ensure_backlog_scaffold() {
    local backlog_dir="$BASE_DIR/.backlog"
    echo "project backlog scaffold:"
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} create $backlog_dir/prds"
        echo -e "  ${BLUE}[dry-run]${NC} create $backlog_dir/plans"
        echo -e "  ${BLUE}[dry-run]${NC} create $backlog_dir/backlog.md"
        return
    fi

    mkdir -p "$backlog_dir/prds" "$backlog_dir/plans"
    if [ ! -f "$backlog_dir/backlog.md" ]; then
        cat > "$backlog_dir/backlog.md" <<'EOF'
## Pending

### [example-feature] Example Feature

- **Priority**: P2
- **Status**: pending
- **Description**: Replace this with your first feature idea.
- **PRD**:
- **Plan**:
EOF
    fi
    echo -e "  ${GREEN}+${NC} Ensured: $backlog_dir/{prds,plans,backlog.md}"
}

discover_agents() {
    local all
    all=$(ls "$SCRIPT_DIR/agents"/*.md 2>/dev/null || true)
    if [ -z "$all" ]; then
        echo ""
        return
    fi
    for file in $all; do
        basename "$file" .md
    done
}

discover_skills() {
    local all
    all=$(ls -d "$SCRIPT_DIR/skills"/* 2>/dev/null || true)
    if [ -z "$all" ]; then
        echo ""
        return
    fi
    for dir in $all; do
        if [ -f "$dir/SKILL.md" ]; then
            basename "$dir"
        fi
    done
}

discover_commands() {
    local all
    all=$(ls "$SCRIPT_DIR/commands"/*.md 2>/dev/null || true)
    if [ -z "$all" ]; then
        echo ""
        return
    fi
    for file in $all; do
        basename "$file" .md
    done
}

prompt_install_scope() {
    if [ -n "$BASE_DIR" ]; then
        return
    fi
    if ! is_interactive; then
        echo -e "${RED}Error: specify --global, --local, or --path${NC}"
        exit 1
    fi
    echo "Install scope:"
    echo "  1) Global ($HOME)"
    echo "  2) Local ($(pwd))"
    echo "  3) Custom path"
    read -p "Choice [1-3]: " scope_choice
    case "$scope_choice" in
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
}

prompt_tools() {
    if [ -n "$TOOLS" ]; then
        return
    fi
    if ! is_interactive; then
        TOOLS="all"
        return
    fi
    echo ""
    echo "Install for which tools?"
    echo "  1) Claude Code only"
    echo "  2) Cursor only"
    echo "  3) Both"
    read -p "Choice [1-3]: " tools_choice
    case "$tools_choice" in
        1) TOOLS="claude" ;;
        2) TOOLS="cursor" ;;
        3) TOOLS="all" ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
}

prompt_mode() {
    if [ -n "$MODE" ]; then
        return
    fi
    if ! is_interactive; then
        MODE="symlink"
        return
    fi
    echo ""
    echo "Install mode:"
    echo "  1) symlink (relative)"
    echo "  2) copy"
    read -p "Choice [1-2]: " mode_choice
    case "$mode_choice" in
        1) MODE="symlink" ;;
        2) MODE="copy" ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
}

prompt_targets_if_needed() {
    if [ "$AGENTS_REQUESTED" = false ] && [ "$SKILLS_REQUESTED" = false ] && [ "$COMMANDS_REQUESTED" = false ] && [ "$FILES_REQUESTED" = false ]; then
        if ! is_interactive; then
            AGENTS_REQUESTED=true
            SKILLS_REQUESTED=true
            COMMANDS_REQUESTED=true
            FILES_REQUESTED=true
            return
        fi
        echo "What do you want to install?"
        echo "  1) Agents"
        echo "  2) Skills"
        echo "  3) Commands"
        echo "  4) Files"
        echo "  5) All"
        read -p "Choice [1-5]: " target_choice
        case "$target_choice" in
            1) AGENTS_REQUESTED=true ;;
            3)
                COMMANDS_REQUESTED=true
                ;;
            2)
                SKILLS_REQUESTED=true
                ;;
            4)
                FILES_REQUESTED=true
                ;;
            5)
                AGENTS_REQUESTED=true
                SKILLS_REQUESTED=true
                COMMANDS_REQUESTED=true
                FILES_REQUESTED=true
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

resolve_agent_selection() {
    local available_agents=()
    while IFS= read -r line; do
        [ -n "$line" ] && available_agents+=("$line")
    done < <(discover_agents)

    if [ "${#available_agents[@]}" -eq 0 ]; then
        echo -e "${RED}No agents found in $SCRIPT_DIR/agents${NC}"
        exit 1
    fi

    if [ -n "$AGENTS_ARG" ]; then
        split_csv "$AGENTS_ARG"
        SELECTED_AGENTS=("${OUT_ARRAY[@]}")
        return
    fi

    if ! is_interactive; then
        SELECTED_AGENTS=("${available_agents[@]}")
        return
    fi
    echo ""
    echo "Available agents:"
    local i=1
    for name in "${available_agents[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    read -p "Select agents (comma-separated indexes or 'a'): " picked
    if [ "$picked" = "a" ] || [ "$picked" = "all" ]; then
        SELECTED_AGENTS=("${available_agents[@]}")
        return
    fi

    split_csv "$picked"
    SELECTED_AGENTS=()
    local idx
    for idx in "${OUT_ARRAY[@]}"; do
        if [ "$idx" -ge 1 ] 2>/dev/null && [ "$idx" -le "${#available_agents[@]}" ]; then
            SELECTED_AGENTS+=("${available_agents[$((idx - 1))]}")
        fi
    done
    if [ "${#SELECTED_AGENTS[@]}" -eq 0 ]; then
        echo -e "${RED}No valid agent selection.${NC}"
        exit 1
    fi
}

resolve_file_selection() {
    if [ -n "$FILES_ARG" ]; then
        split_csv "$FILES_ARG"
        SELECTED_FILE_GROUPS=("${OUT_ARRAY[@]}")
        return
    fi

    if ! is_interactive; then
        SELECTED_FILE_GROUPS=("${DEFAULT_FILES[@]}")
        return
    fi
    echo ""
    echo "Available file groups:"
    echo "  1) commands"
    echo "  2) skills"
    echo "  3) backlog"
    echo "  a) all"
    read -p "Select file groups (comma-separated indexes or 'a'): " picked
    if [ "$picked" = "a" ] || [ "$picked" = "all" ]; then
        SELECTED_FILE_GROUPS=("${AVAILABLE_FILE_GROUPS[@]}")
        return
    fi

    split_csv "$picked"
    SELECTED_FILE_GROUPS=()
    local idx
    for idx in "${OUT_ARRAY[@]}"; do
        case "$idx" in
            1) SELECTED_FILE_GROUPS+=("commands") ;;
            2) SELECTED_FILE_GROUPS+=("skills") ;;
            3) SELECTED_FILE_GROUPS+=("backlog") ;;
        esac
    done
    if [ "${#SELECTED_FILE_GROUPS[@]}" -eq 0 ]; then
        echo -e "${RED}No valid file group selection.${NC}"
        exit 1
    fi
}

resolve_skills_selection() {
    local available_skills=()
    while IFS= read -r line; do
        [ -n "$line" ] && available_skills+=("$line")
    done < <(discover_skills)

    if [ "${#available_skills[@]}" -eq 0 ]; then
        echo -e "${RED}No skills found in $SCRIPT_DIR/skills${NC}"
        exit 1
    fi

    if [ -n "$SKILLS_ARG" ]; then
        split_csv "$SKILLS_ARG"
        SELECTED_SKILLS=("${OUT_ARRAY[@]}")
        return
    fi

    if ! is_interactive; then
        SELECTED_SKILLS=("${available_skills[@]}")
        return
    fi
    echo ""
    echo "Available skills:"
    local i=1
    for name in "${available_skills[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    read -p "Select skills (comma-separated indexes or 'a'): " picked
    if [ "$picked" = "a" ] || [ "$picked" = "all" ]; then
        SELECTED_SKILLS=("${available_skills[@]}")
        return
    fi

    split_csv "$picked"
    SELECTED_SKILLS=()
    local idx
    for idx in "${OUT_ARRAY[@]}"; do
        if [ "$idx" -ge 1 ] 2>/dev/null && [ "$idx" -le "${#available_skills[@]}" ]; then
            SELECTED_SKILLS+=("${available_skills[$((idx - 1))]}")
        fi
    done
    if [ "${#SELECTED_SKILLS[@]}" -eq 0 ]; then
        echo -e "${RED}No valid skills selection.${NC}"
        exit 1
    fi
}

resolve_commands_selection() {
    local available_commands=()
    while IFS= read -r line; do
        [ -n "$line" ] && available_commands+=("$line")
    done < <(discover_commands)

    if [ "${#available_commands[@]}" -eq 0 ]; then
        echo -e "${RED}No commands found in $SCRIPT_DIR/commands${NC}"
        exit 1
    fi

    if [ -n "$COMMANDS_ARG" ]; then
        split_csv "$COMMANDS_ARG"
        SELECTED_COMMANDS=("${OUT_ARRAY[@]}")
        return
    fi

    if ! is_interactive; then
        SELECTED_COMMANDS=("${available_commands[@]}")
        return
    fi
    echo ""
    echo "Available commands:"
    local i=1
    for name in "${available_commands[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    read -p "Select commands (comma-separated indexes or 'a'): " picked
    if [ "$picked" = "a" ] || [ "$picked" = "all" ]; then
        SELECTED_COMMANDS=("${available_commands[@]}")
        return
    fi

    split_csv "$picked"
    SELECTED_COMMANDS=()
    local idx
    for idx in "${OUT_ARRAY[@]}"; do
        if [ "$idx" -ge 1 ] 2>/dev/null && [ "$idx" -le "${#available_commands[@]}" ]; then
            SELECTED_COMMANDS+=("${available_commands[$((idx - 1))]}")
        fi
    done
    if [ "${#SELECTED_COMMANDS[@]}" -eq 0 ]; then
        echo -e "${RED}No valid commands selection.${NC}"
        exit 1
    fi
}

install_skills_for_tool() {
    local tool="$1"
    shift
    local selected_skills=("$@")
    local tool_dir
    tool_dir="$(tool_dir_name "$tool")"
    local target_skills_dir="$BASE_DIR/$tool_dir/skills"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$target_skills_dir"
    fi
    echo "$tool skills:"
    for skill in "${selected_skills[@]}"; do
        local source="$SCRIPT_DIR/skills/$skill"
        local target="$target_skills_dir/$skill"
        if [ ! -f "$source/SKILL.md" ]; then
            echo -e "  ${YELLOW}!${NC} Skill not found: $skill"
            continue
        fi
        install_entry "$source" "$target" "$MODE" "dir"
    done
}

install_commands_for_tool() {
    local tool="$1"
    shift
    local selected_commands=("$@")
    local tool_dir
    tool_dir="$(tool_dir_name "$tool")"
    local target_commands_dir="$BASE_DIR/$tool_dir/commands"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$target_commands_dir"
    fi
    echo "$tool command files:"
    for cmd in "${selected_commands[@]}"; do
        local source="$SCRIPT_DIR/commands/$cmd.md"
        local target="$target_commands_dir/$cmd.md"
        if [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Command not found: $cmd"
            continue
        fi
        install_entry "$source" "$target" "$MODE" "file"
    done
}

show_status() {
    local base="$1"
    echo "Base: $base"
    for tool in claude cursor; do
        local td
        td="$(tool_dir_name "$tool")"
        echo "  $tool:"
        echo "    agents:  $(path_type "$base/$td/agents")"
        echo "    commands: $(path_type "$base/$td/commands")"
        echo "    skills:   $(path_type "$base/$td/skills")"
    done
    echo "  project backlog: $(path_type "$base/.backlog")"
}

update_repo() {
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        echo -e "${RED}Error: Not a git repository.${NC}"
        exit 1
    fi
    local before
    before=$(cd "$SCRIPT_DIR" && git rev-parse --short HEAD)
    echo "Current: $before"
    (cd "$SCRIPT_DIR" && git pull --ff-only)
    local after
    after=$(cd "$SCRIPT_DIR" && git rev-parse --short HEAD)
    echo "Updated: $before -> $after"
}

while [ $# -gt 0 ]; do
    case "$1" in
        install|status|update)
            COMMAND="$1"
            ;;
        --agents)
            AGENTS_REQUESTED=true
            if [ -n "$2" ] && [[ "$2" != --* ]] && [[ "$2" != "install" ]] && [[ "$2" != "status" ]] && [[ "$2" != "update" ]]; then
                AGENTS_ARG="$2"
                shift
            fi
            ;;
        --skills)
            SKILLS_REQUESTED=true
            if [ -n "$2" ] && [[ "$2" != --* ]] && [[ "$2" != "install" ]] && [[ "$2" != "status" ]] && [[ "$2" != "update" ]]; then
                SKILLS_ARG="$2"
                shift
            fi
            ;;
        --commands)
            COMMANDS_REQUESTED=true
            if [ -n "$2" ] && [[ "$2" != --* ]] && [[ "$2" != "install" ]] && [[ "$2" != "status" ]] && [[ "$2" != "update" ]]; then
                COMMANDS_ARG="$2"
                shift
            fi
            ;;
        --files)
            FILES_REQUESTED=true
            if [ -n "$2" ] && [[ "$2" != --* ]] && [[ "$2" != "install" ]] && [[ "$2" != "status" ]] && [[ "$2" != "update" ]]; then
                FILES_ARG="$2"
                shift
            fi
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
        --mode)
            shift
            MODE="$1"
            ;;
        --tools)
            shift
            TOOLS="$1"
            ;;
        --dry-run|-d)
            DRY_RUN=true
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

ensure_repo_checkout "$@"

if [ "$COMMAND" = "status" ]; then
    echo -e "${CYAN}Agentfiles status${NC}"
    show_status "$HOME"
    if [ "$(pwd)" != "$HOME" ]; then
        echo ""
        show_status "$(pwd)"
    fi
    exit 0
fi

if [ "$COMMAND" = "update" ]; then
    update_repo
    exit 0
fi

prompt_targets_if_needed
prompt_install_scope
prompt_tools
prompt_mode

if [ "$MODE" != "symlink" ] && [ "$MODE" != "copy" ]; then
    echo -e "${RED}Invalid --mode. Use symlink or copy.${NC}"
    exit 1
fi

if [ "$TOOLS" != "claude" ] && [ "$TOOLS" != "cursor" ] && [ "$TOOLS" != "all" ]; then
    echo -e "${RED}Invalid --tools. Use claude, cursor, or all.${NC}"
    exit 1
fi

if [ "$AGENTS_REQUESTED" = true ]; then
    resolve_agent_selection
fi

if [ "$SKILLS_REQUESTED" = true ]; then
    resolve_skills_selection
fi

if [ "$COMMANDS_REQUESTED" = true ]; then
    resolve_commands_selection
fi

if [ "$FILES_REQUESTED" = true ]; then
    resolve_file_selection
fi

echo -e "${CYAN}Installing to: $BASE_DIR${NC}"
echo -e "Mode: ${GRAY}$MODE${NC} | Tools: ${GRAY}$TOOLS${NC}"

TOOLS_LIST=()
if [ "$TOOLS" = "all" ]; then
    TOOLS_LIST=("claude" "cursor")
else
    TOOLS_LIST=("$TOOLS")
fi

if [ "$AGENTS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Agents${NC}: ${SELECTED_AGENTS[*]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_agents_for_tool "$tool" "${SELECTED_AGENTS[@]}"
    done
fi

if [ "$SKILLS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Skills${NC}: ${SELECTED_SKILLS[*]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_skills_for_tool "$tool" "${SELECTED_SKILLS[@]}"
    done
fi

if [ "$COMMANDS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Commands${NC}: ${SELECTED_COMMANDS[*]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_commands_for_tool "$tool" "${SELECTED_COMMANDS[@]}"
    done
fi

if [ "$FILES_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Files${NC}: ${SELECTED_FILE_GROUPS[*]}"
    for group in "${SELECTED_FILE_GROUPS[@]}"; do
        if [ "$group" = "backlog" ]; then
            ensure_backlog_scaffold
            continue
        fi
        for tool in "${TOOLS_LIST[@]}"; do
            echo "$tool $group:"
            install_file_group_for_tool "$tool" "$group"
        done
    done
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}Dry-run complete. No changes were made.${NC}"
else
    echo -e "${GREEN}Done.${NC}"
fi
