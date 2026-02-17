#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/miguelalcalde/agentfiles.git"
BOOTSTRAP_TMP_DIR=""
BOOTSTRAP_ACTIVE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

COMMAND="install"
BASE_DIR=""
TOOLS=""
MODE=""
DRY_RUN=false
CANONICAL_ROOT=""
OVERWRITE_EXISTING=""
VERBOSE=false

AGENTS_REQUESTED=false
FILES_REQUESTED=false
SKILLS_REQUESTED=false
COMMANDS_REQUESTED=false
AGENTS_ARG=""
FILES_ARG=""
SKILLS_ARG=""
COMMANDS_ARG=""
ORIGINAL_ARGS=("$@")

cleanup_bootstrap_tmp() {
    if [ "$BOOTSTRAP_ACTIVE" = true ] && [ -n "$BOOTSTRAP_TMP_DIR" ] && [ -d "$BOOTSTRAP_TMP_DIR" ]; then
        # Avoid rm -rf; remove recursively via Python for portability.
        python3 - <<'PY' "$BOOTSTRAP_TMP_DIR"
import shutil
import sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
    fi
}

ensure_repo_checkout() {
    if [ -d "$SCRIPT_DIR/agents" ] && [ -d "$SCRIPT_DIR/commands" ] && [ -d "$SCRIPT_DIR/skills" ]; then
        return
    fi

    echo -e "${CYAN}Agentfiles bootstrap${NC}"
    echo "Preparing temporary source checkout..."
    echo ""

    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is required but not installed.${NC}"
        exit 1
    fi

    BOOTSTRAP_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/agentfiles-bootstrap.XXXXXX")"
    BOOTSTRAP_ACTIVE=true
    trap cleanup_bootstrap_tmp EXIT INT TERM
    local bootstrap_repo_dir="$BOOTSTRAP_TMP_DIR/repo"
    echo "Cloning..."
    git clone --quiet "$REPO_URL" "$bootstrap_repo_dir"
    SCRIPT_DIR="$bootstrap_repo_dir"

    echo ""
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
    echo "  --files [x,y]  Install file groups (auto-discovered top-level directories)"
    echo ""
    echo "Scope and mode:"
    echo "  --global       Install to home directory (~)"
    echo "  --local        Install to current project directory"
    echo "  --path DIR     Install to custom base directory"
    echo "  --mode MODE    Install mode: symlink | copy"
    echo "  --tools TOOLS  claude | cursor | all"
    echo "  --dry-run      Preview changes without writing"
    echo "  --verbose      Print debug diagnostics"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh"
    echo "  ./setup.sh --agents"
    echo "  ./setup.sh --skills"
    echo "  ./setup.sh --commands"
    echo "  ./setup.sh --agents picker,planner --mode symlink --global --tools all"
    echo "  ./setup.sh --skills feature-workflow,code-review --mode symlink --global --tools all"
    echo "  ./setup.sh --commands pick,plan --mode symlink --global --tools all"
    echo "  ./setup.sh --files backlog --mode symlink --local"
    echo "  ./setup.sh --files backlog --mode copy --local"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${GRAY}[verbose] $*${NC}"
    fi
}

print_verbose_diagnostics() {
    if [ "$VERBOSE" != true ]; then
        return
    fi
    local tty_in="no"
    local tty_out="no"
    local tty_dev="no"
    [ -t 0 ] && tty_in="yes"
    [ -t 1 ] && tty_out="yes"
    [ -r /dev/tty ] && tty_dev="yes"
    echo -e "${CYAN}Verbose diagnostics${NC}:"
    verbose_log "pwd=$(pwd)"
    verbose_log "script_dir=$SCRIPT_DIR"
    verbose_log "command=$COMMAND"
    verbose_log "bootstrap_active=$BOOTSTRAP_ACTIVE bootstrap_tmp_dir=$BOOTSTRAP_TMP_DIR"
    verbose_log "stdin_tty=$tty_in stdout_tty=$tty_out dev_tty_readable=$tty_dev"
}

is_interactive() {
    # Treat piped execution (e.g. curl | bash) as interactive when a terminal is available.
    ([ -t 0 ] && [ -t 1 ]) || ([ -t 1 ] && [ -r /dev/tty ])
}

prompt_read() {
    local __var_name="$1"
    local __prompt="$2"
    local __value=""
    if [ -r /dev/tty ]; then
        IFS= read -r -p "$__prompt" __value < /dev/tty
    else
        IFS= read -r -p "$__prompt" __value
    fi
    printf -v "$__var_name" '%s' "$__value"
}

split_csv() {
    local input="$1"
    input="${input// /}"
    IFS=',' read -r -a OUT_ARRAY <<< "$input"
}

csv_contains() {
    local needle="$1"
    shift
    local value
    for value in "$@"; do
        if [ "$value" = "$needle" ]; then
            return 0
        fi
    done
    return 1
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

should_overwrite_target() {
    local _target="$1"
    verbose_log "overwrite policy target=$_target overwrite_existing=$OVERWRITE_EXISTING"
    if [ "$OVERWRITE_EXISTING" = "true" ]; then
        return 0
    fi
    return 1
}

install_entry() {
    local source="$1"
    local target="$2"
    local mode="$3"
    local source_type="$4"
    local current_type
    current_type=$(path_type "$target")
    verbose_log "install_entry source=$source target=$target mode=$mode source_type=$source_type current_type=$current_type dry_run=$DRY_RUN"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} $mode $source -> $target"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ "$current_type" != "none" ]; then
        if ! should_overwrite_target "$target"; then
            verbose_log "skip target=$target reason=exists_and_overwrite_disabled"
            echo -e "  ${GRAY}-${NC} Skipped: $target"
            return
        fi
        verbose_log "overwrite target=$target reason=exists_and_overwrite_enabled"
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
        local source="$CANONICAL_ROOT/agents/$agent.md"
        local target="$target_agents_dir/$agent.md"
        if [ "$DRY_RUN" = false ] && [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Agent not found: $agent"
            continue
        fi
        install_entry "$source" "$target" "$MODE" "file"
    done
}

map_file_group_target() {
    local group="$1"
    echo ".$group"
}

install_file_group() {
    local group="$1"
    local target_name
    target_name="$(map_file_group_target "$group")"
    # File groups are root-level artifacts; always materialize in place.
    install_entry "$SCRIPT_DIR/$group" "$BASE_DIR/$target_name" "copy" "dir"
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
        local name
        name=$(basename "$dir")
        case "$name" in
            *.backup.*) continue ;;
        esac
        if [ -f "$dir/SKILL.md" ]; then
            echo "$name"
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

discover_file_groups() {
    local entry
    for entry in "$SCRIPT_DIR"/*; do
        [ -d "$entry" ] || continue
        local name
        name=$(basename "$entry")
        case "$name" in
            .* ) continue ;;
            agents|commands|skills|settings) continue ;;
        esac
        echo "$name"
    done
}

prompt_install_scope() {
    if [ -n "$BASE_DIR" ]; then
        return
    fi
    if ! is_interactive; then
        BASE_DIR="$HOME"
        echo -e "${YELLOW}Non-interactive run detected; defaulting to --global (${BASE_DIR}).${NC}"
        return
    fi
    echo ""
    echo -e "${BOLD}Install scope${NC}"
    echo "  1) Global ($HOME)"
    echo "  2) Local ($(pwd))"
    echo "  3) Custom path"
    echo ""
    prompt_read scope_choice "Choice [1-3] (default: 2 - local/project): "
    scope_choice="${scope_choice:-2}"
    case "$scope_choice" in
        1) BASE_DIR="$HOME" ;;
        2) BASE_DIR="$(pwd)" ;;
        3)
            prompt_read BASE_DIR "Enter path: "
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
    echo -e "${BOLD}Install tools${NC}"
    echo "  1) Claude Code only"
    echo "  2) Cursor only"
    echo "  a) all (both Claude and Cursor)"
    echo ""
    prompt_read tools_choice "Choice [1-2 or a] (default: a - all): "
    tools_choice="${tools_choice:-a}"
    case "$tools_choice" in
        1) TOOLS="claude" ;;
        2) TOOLS="cursor" ;;
        a|all) TOOLS="all" ;;
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
    echo -e "${BOLD}Install mode${NC}"
    echo "  1) symlink (relative)"
    echo "  2) copy"
    echo ""
    prompt_read mode_choice "Choice [1-2] (default: 1 - symlink): "
    mode_choice="${mode_choice:-1}"
    case "$mode_choice" in
        1) MODE="symlink" ;;
        2) MODE="copy" ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
}

prompt_overwrite_policy() {
    if ! is_interactive; then
        OVERWRITE_EXISTING="false"
        verbose_log "overwrite policy defaulted to false (non-interactive)"
        return
    fi

    if [ -n "$OVERWRITE_EXISTING" ]; then
        verbose_log "overwrite policy pre-set to $OVERWRITE_EXISTING"
        return
    fi

    echo ""
    prompt_read overwrite_choice "Overwrite existing paths when present? [y/N]: "
    overwrite_choice="${overwrite_choice//[[:space:]]/}"
    verbose_log "overwrite prompt raw choice='$overwrite_choice'"
    case "$overwrite_choice" in
        y|Y|yes|YES|Yes)
            OVERWRITE_EXISTING="true"
            ;;
        *)
            OVERWRITE_EXISTING="false"
            ;;
    esac
    verbose_log "overwrite policy resolved to $OVERWRITE_EXISTING"
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
        echo ""
        echo -e "${BOLD}What do you want to install?${NC}"
        echo "  1) Agents"
        echo "  2) Skills"
        echo "  3) Commands"
        echo "  4) Files"
        echo "  a) all"
        echo ""
        prompt_read target_choice "Choice [1-4 comma-separated or a] (default: a - all): "
        target_choice="${target_choice:-a}"
        split_csv "$target_choice"

        if csv_contains "a" "${OUT_ARRAY[@]}" || csv_contains "all" "${OUT_ARRAY[@]}"; then
            AGENTS_REQUESTED=true
            SKILLS_REQUESTED=true
            COMMANDS_REQUESTED=true
            FILES_REQUESTED=true
            return
        fi

        local choice
        for choice in "${OUT_ARRAY[@]}"; do
            case "$choice" in
                1) AGENTS_REQUESTED=true ;;
                2) SKILLS_REQUESTED=true ;;
                3) COMMANDS_REQUESTED=true ;;
                4) FILES_REQUESTED=true ;;
                *)
                    echo "Invalid choice: $choice"
                    exit 1
                    ;;
            esac
        done

        if [ "$AGENTS_REQUESTED" = false ] && [ "$SKILLS_REQUESTED" = false ] && [ "$COMMANDS_REQUESTED" = false ] && [ "$FILES_REQUESTED" = false ]; then
            echo "Invalid choice"
            exit 1
        fi
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
    echo -e "${BOLD}Available agents${NC}"
    local i=1
    for name in "${available_agents[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    echo ""
    prompt_read picked "Select agents (comma-separated indexes or 'a', default: a): "
    picked="${picked:-a}"
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
    local available_groups=()
    while IFS= read -r line; do
        [ -n "$line" ] && available_groups+=("$line")
    done < <(discover_file_groups)

    if [ "${#available_groups[@]}" -eq 0 ]; then
        echo -e "${RED}No file groups found. Add top-level directories (excluding reserved/hidden).${NC}"
        exit 1
    fi

    if [ -n "$FILES_ARG" ]; then
        split_csv "$FILES_ARG"
        SELECTED_FILE_GROUPS=()
        local requested
        for requested in "${OUT_ARRAY[@]}"; do
            local found=false
            local existing
            for existing in "${available_groups[@]}"; do
                if [ "$requested" = "$existing" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                echo -e "${RED}Unknown file group: $requested${NC}"
                exit 1
            fi
            SELECTED_FILE_GROUPS+=("$requested")
        done
        return
    fi

    if ! is_interactive; then
        SELECTED_FILE_GROUPS=("${available_groups[@]}")
        return
    fi
    echo ""
    echo -e "${BOLD}Available file groups${NC}"
    local i=1
    local group
    for group in "${available_groups[@]}"; do
        local mapped
        mapped="$(map_file_group_target "$group")"
        if [ "$mapped" != "$group" ]; then
            echo "  $i) $group -> $mapped"
        else
            echo "  $i) $group"
        fi
        i=$((i + 1))
    done
    echo "  a) all"
    echo ""
    prompt_read picked "Select file groups (comma-separated indexes or 'a', default: a): "
    picked="${picked:-a}"
    if [ "$picked" = "a" ] || [ "$picked" = "all" ]; then
        SELECTED_FILE_GROUPS=("${available_groups[@]}")
        return
    fi

    split_csv "$picked"
    SELECTED_FILE_GROUPS=()
    local idx
    for idx in "${OUT_ARRAY[@]}"; do
        if [ "$idx" -ge 1 ] 2>/dev/null && [ "$idx" -le "${#available_groups[@]}" ]; then
            SELECTED_FILE_GROUPS+=("${available_groups[$((idx - 1))]}")
        fi
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
    echo -e "${BOLD}Available skills${NC}"
    local i=1
    for name in "${available_skills[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    echo ""
    prompt_read picked "Select skills (comma-separated indexes or 'a', default: a): "
    picked="${picked:-a}"
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
    echo -e "${BOLD}Available commands${NC}"
    local i=1
    for name in "${available_commands[@]}"; do
        echo "  $i) $name"
        i=$((i + 1))
    done
    echo "  a) all"
    echo ""
    prompt_read picked "Select commands (comma-separated indexes or 'a', default: a): "
    picked="${picked:-a}"
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
        local source="$CANONICAL_ROOT/skills/$skill"
        local target="$target_skills_dir/$skill"
        if [ "$DRY_RUN" = false ] && [ ! -f "$source/SKILL.md" ]; then
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
        local source="$CANONICAL_ROOT/commands/$cmd.md"
        local target="$target_commands_dir/$cmd.md"
        if [ "$DRY_RUN" = false ] && [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Command not found: $cmd"
            continue
        fi
        install_entry "$source" "$target" "$MODE" "file"
    done
}

resolve_canonical_root() {
    if [ "$BASE_DIR" = "$HOME" ]; then
        CANONICAL_ROOT="$HOME/.agents"
    else
        CANONICAL_ROOT="$BASE_DIR/.agents"
    fi
}

stage_agents_to_canonical() {
    local selected_agents=("$@")
    [ "${#selected_agents[@]}" -gt 0 ] || return
    local target_dir="$CANONICAL_ROOT/agents"
    [ "$DRY_RUN" = false ] && mkdir -p "$target_dir"
    echo "canonical agents:"
    local agent
    for agent in "${selected_agents[@]}"; do
        local source="$SCRIPT_DIR/agents/$agent.md"
        local target="$target_dir/$agent.md"
        if [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Agent not found: $agent"
            continue
        fi
        install_entry "$source" "$target" "copy" "file"
    done
}

stage_skills_to_canonical() {
    local selected_skills=("$@")
    [ "${#selected_skills[@]}" -gt 0 ] || return
    local target_dir="$CANONICAL_ROOT/skills"
    [ "$DRY_RUN" = false ] && mkdir -p "$target_dir"
    echo "canonical skills:"
    local skill
    for skill in "${selected_skills[@]}"; do
        local source="$SCRIPT_DIR/skills/$skill"
        local target="$target_dir/$skill"
        if [ ! -f "$source/SKILL.md" ]; then
            echo -e "  ${YELLOW}!${NC} Skill not found: $skill"
            continue
        fi
        install_entry "$source" "$target" "copy" "dir"
    done
}

stage_commands_to_canonical() {
    local selected_commands=("$@")
    [ "${#selected_commands[@]}" -gt 0 ] || return
    local target_dir="$CANONICAL_ROOT/commands"
    [ "$DRY_RUN" = false ] && mkdir -p "$target_dir"
    echo "canonical commands:"
    local cmd
    for cmd in "${selected_commands[@]}"; do
        local source="$SCRIPT_DIR/commands/$cmd.md"
        local target="$target_dir/$cmd.md"
        if [ ! -f "$source" ]; then
            echo -e "  ${YELLOW}!${NC} Command not found: $cmd"
            continue
        fi
        install_entry "$source" "$target" "copy" "file"
    done
}

json_array_from_list() {
    local first=true
    printf "["
    local item
    for item in "$@"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ", "
        fi
        item="${item//\\/\\\\}"
        item="${item//\"/\\\"}"
        printf "\"%s\"" "$item"
    done
    printf "]"
}

write_manifest() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} write manifest: $CANONICAL_ROOT/manifest.json"
        return
    fi

    mkdir -p "$CANONICAL_ROOT"

    local scope="local"
    if [ "$BASE_DIR" = "$HOME" ]; then
        scope="global"
    fi

    local agents_json skills_json commands_json files_json
    agents_json=$(json_array_from_list "${SELECTED_AGENTS[@]}")
    skills_json=$(json_array_from_list "${SELECTED_SKILLS[@]}")
    commands_json=$(json_array_from_list "${SELECTED_COMMANDS[@]}")
    files_json=$(json_array_from_list "${SELECTED_FILE_GROUPS[@]}")

    cat > "$CANONICAL_ROOT/manifest.json" <<EOF
{
  "version": 1,
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scope": "$scope",
  "base_dir": "$BASE_DIR",
  "canonical_root": "$CANONICAL_ROOT",
  "mode": "$MODE",
  "tools": "$TOOLS",
  "selection": {
    "agents": $agents_json,
    "skills": $skills_json,
    "commands": $commands_json,
    "files": $files_json
  }
}
EOF
    echo -e "  ${GREEN}+${NC} Wrote: $CANONICAL_ROOT/manifest.json"
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
        --verbose|-v)
            VERBOSE=true
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

ensure_repo_checkout "${ORIGINAL_ARGS[@]}"
print_verbose_diagnostics

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
if [ "$AGENTS_REQUESTED" = true ] || [ "$SKILLS_REQUESTED" = true ] || [ "$COMMANDS_REQUESTED" = true ]; then
    prompt_tools
fi
prompt_mode
prompt_overwrite_policy

if [ "$MODE" != "symlink" ] && [ "$MODE" != "copy" ]; then
    echo -e "${RED}Invalid --mode. Use symlink or copy.${NC}"
    exit 1
fi

if [ "$AGENTS_REQUESTED" = true ] || [ "$SKILLS_REQUESTED" = true ] || [ "$COMMANDS_REQUESTED" = true ]; then
    if [ "$TOOLS" != "claude" ] && [ "$TOOLS" != "cursor" ] && [ "$TOOLS" != "all" ]; then
        echo -e "${RED}Invalid --tools. Use claude, cursor, or all.${NC}"
        exit 1
    fi
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
resolve_canonical_root
if [ "$AGENTS_REQUESTED" = true ] || [ "$SKILLS_REQUESTED" = true ] || [ "$COMMANDS_REQUESTED" = true ]; then
    echo -e "Mode: ${GRAY}$MODE${NC} | Tools: ${GRAY}$TOOLS${NC}"
    echo -e "Canonical root: ${GRAY}$CANONICAL_ROOT${NC}"
else
    echo -e "Mode: ${GRAY}$MODE${NC}"
fi

TOOLS_LIST=()
if [ "$AGENTS_REQUESTED" = true ] || [ "$SKILLS_REQUESTED" = true ] || [ "$COMMANDS_REQUESTED" = true ]; then
    if [ "$TOOLS" = "all" ]; then
        TOOLS_LIST=("claude" "cursor")
    else
        TOOLS_LIST=("$TOOLS")
    fi
fi

if [ "$AGENTS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Agents${NC}: ${SELECTED_AGENTS[*]}"
    stage_agents_to_canonical "${SELECTED_AGENTS[@]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_agents_for_tool "$tool" "${SELECTED_AGENTS[@]}"
    done
fi

if [ "$SKILLS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Skills${NC}: ${SELECTED_SKILLS[*]}"
    stage_skills_to_canonical "${SELECTED_SKILLS[@]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_skills_for_tool "$tool" "${SELECTED_SKILLS[@]}"
    done
fi

if [ "$COMMANDS_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Commands${NC}: ${SELECTED_COMMANDS[*]}"
    stage_commands_to_canonical "${SELECTED_COMMANDS[@]}"
    for tool in "${TOOLS_LIST[@]}"; do
        install_commands_for_tool "$tool" "${SELECTED_COMMANDS[@]}"
    done
fi

if [ "$FILES_REQUESTED" = true ]; then
    echo ""
    echo -e "${CYAN}Files${NC}: ${SELECTED_FILE_GROUPS[*]}"
    for group in "${SELECTED_FILE_GROUPS[@]}"; do
        local_target="$(map_file_group_target "$group")"
        echo "$group -> $local_target:"
        install_file_group "$group"
    done
fi

echo ""
echo -e "${CYAN}Manifest${NC}:"
write_manifest

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}Dry-run complete. No changes were made.${NC}"
else
    echo -e "${GREEN}Done.${NC}"
fi
