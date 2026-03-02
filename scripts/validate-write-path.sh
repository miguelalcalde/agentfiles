#!/bin/bash
# validate-write-path.sh — PreToolUse hook for Claude Code
#
# Validates that Write/Edit operations target only allowed paths
# based on the invoking agent's role.
#
# Hook contract:
#   stdin:  JSON with { "tool_name": "Write|Edit", "tool_input": { "file_path": "..." } }
#   exit 0: allow the operation
#   exit 2: block the operation (stdout message shown to agent)
#
# The agent name is passed via CLAUDE_AGENT_NAME environment variable
# (set by the hook configuration in .claude/settings.json).

set -euo pipefail

INPUT=$(cat)

# Extract the file_path from the JSON tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
path = tool_input.get('file_path', '')
print(path)
" 2>/dev/null || echo "")

# If no file path found, allow (not a write-path operation)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Normalize to absolute path
if [[ "$FILE_PATH" != /* ]]; then
    FILE_PATH="$(pwd)/$FILE_PATH"
fi

AGENT="${CLAUDE_AGENT_NAME:-unknown}"

case "$AGENT" in
    triager)
        if [[ "$FILE_PATH" == */.backlog/backlog.md ]] || \
           [[ "$FILE_PATH" == */.backlog/prds/*.md ]]; then
            exit 0
        fi
        ;;
    planner)
        if [[ "$FILE_PATH" == */.backlog/plans/*.md ]] || \
           [[ "$FILE_PATH" == */.backlog/prds/*.md ]] || \
           [[ "$FILE_PATH" == */.cursor/plans/*.md ]]; then
            exit 0
        fi
        ;;
    refiner)
        if [[ "$FILE_PATH" == */.backlog/prds/*.md ]]; then
            exit 0
        fi
        ;;
    implementer|conductor)
        # Full access — no restrictions
        exit 0
        ;;
    *)
        # Unknown agent — fail open to avoid breaking unrelated workflows
        exit 0
        ;;
esac

# Path not in allowed list for this agent
echo "BLOCKED: Agent '$AGENT' cannot write to '$FILE_PATH'. Check the agent's Write Boundaries in its skill file."
exit 2
