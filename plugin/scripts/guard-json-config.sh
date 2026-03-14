#!/bin/bash
#
# guard-json-config.sh — Validate JSON config files before/after writes
#
# Used as a hook handler to prevent malformed JSON from breaking Claude Code.
# - PreToolUse (Write): validates content BEFORE writing → blocks if invalid
# - PostToolUse (Edit): validates file AFTER editing → feeds error back to Claude
#
# Reads hook input from stdin (JSON with tool_input).
# Only acts on known Claude Code config files; passes through silently for others.
#
# Exit codes:
#   0 = valid JSON or not a config file (allow)
#   2 = invalid JSON in a config file (block/feedback)

set -euo pipefail

INPUT=$(cat)

HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Determine if this is a Claude Code config file we should guard
is_config_file() {
    local path="$1"
    case "$path" in
        */settings.json|*/settings.local.json) return 0 ;;
        */.mcp.json) return 0 ;;
        */.lsp.json) return 0 ;;
        */lsp.json) return 0 ;;
        */.claude.json) return 0 ;;
        */config.json)
            # Only guard team configs under .claude/teams/
            if echo "$path" | grep -q '\.claude/teams/'; then
                return 0
            fi
            return 1
            ;;
        */automations-registry.json) return 0 ;;
        *) return 1 ;;
    esac
}

# Skip non-config files silently
if [ -z "$FILE_PATH" ] || ! is_config_file "$FILE_PATH"; then
    exit 0
fi

if [ "$HOOK_EVENT" = "PreToolUse" ]; then
    # For Write: validate the CONTENT that is about to be written
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

    if [ -z "$CONTENT" ]; then
        exit 0
    fi

    # Check if content is valid JSON
    ERROR=$(echo "$CONTENT" | jq . 2>&1 >/dev/null) || true
    if ! echo "$CONTENT" | jq . >/dev/null 2>&1; then
        echo "BLOCKED: Invalid JSON would be written to $FILE_PATH" >&2
        echo "" >&2
        echo "jq error: $ERROR" >&2
        echo "" >&2
        echo "Fix the JSON before writing. Common issues:" >&2
        echo "  - Trailing commas after last element" >&2
        echo "  - Missing commas between elements" >&2
        echo "  - Unescaped quotes in strings" >&2
        echo "  - Missing closing braces/brackets" >&2
        exit 2
    fi

elif [ "$HOOK_EVENT" = "PostToolUse" ]; then
    # For Edit: validate the RESULTING file after the edit
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    ERROR=$(jq . "$FILE_PATH" 2>&1 >/dev/null) || true
    if ! jq . "$FILE_PATH" >/dev/null 2>&1; then
        echo "WARNING: Edit produced invalid JSON in $FILE_PATH" >&2
        echo "" >&2
        echo "jq error: $ERROR" >&2
        echo "" >&2
        echo "The file is now broken. Read the file, fix the JSON, and rewrite it." >&2
        exit 2
    fi
fi

exit 0
