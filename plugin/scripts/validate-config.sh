#!/bin/bash
#
# validate-config.sh - Validate Claude Code configurations against schemas
#
# Usage: ./validate-config.sh <type> <content>
#   type: hooks | skill | subagent | permissions | custom-commands
#   content: JSON string or file path to validate
#
# Examples:
#   ./validate-config.sh hooks '{"hooks":{"PreToolUse":[...]}}'
#   ./validate-config.sh skill ./my-skill.md
#   echo '{"hooks":{...}}' | ./validate-config.sh hooks -
#
# Exit codes:
#   0 = Valid configuration
#   1 = Invalid configuration (details printed to stderr)
#   2 = Usage error

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_DIR="$SCRIPT_DIR/../schemas"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $1" >&2
}

success() {
    echo -e "${GREEN}VALID:${NC} $1"
}

usage() {
    echo "Usage: $0 <type> <content>"
    echo ""
    echo "Types: hooks, skill, subagent, permissions, custom-commands"
    echo ""
    echo "Content can be:"
    echo "  - A JSON/YAML string"
    echo "  - A file path"
    echo "  - '-' to read from stdin"
    exit 2
}

# Valid hook events (from schema)
VALID_HOOK_EVENTS=(
    "SessionStart"
    "SessionEnd"
    "UserPromptSubmit"
    "PreToolUse"
    "PostToolUse"
    "PostToolUseFailure"
    "PermissionRequest"
    "Notification"
    "Stop"
    "PreCompact"
    "SubagentStart"
    "SubagentStop"
)

# Invalid/non-existent hook events (common mistakes)
INVALID_HOOK_EVENTS=(
    "PreCommit"
    "PostCommit"
    "PreBash"
    "PostBash"
    "PreEdit"
    "PostEdit"
    "BeforeToolUse"
    "AfterToolUse"
    "OnCommit"
    "OnPush"
)

# Valid hook types
VALID_HOOK_TYPES=("command" "prompt" "agent")

# Valid subagent tools
VALID_TOOLS=("Read" "Grep" "Glob" "Bash" "Edit" "Write" "WebFetch" "WebSearch" "Task" "NotebookEdit")

# Valid models
VALID_MODELS=("opus" "sonnet" "haiku")

validate_hooks() {
    local content="$1"
    local errors=0

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed"
        exit 1
    fi

    # Parse JSON
    if ! echo "$content" | jq . > /dev/null 2>&1; then
        error "Invalid JSON format"
        return 1
    fi

    # Extract hook event names
    local events=$(echo "$content" | jq -r '.hooks | keys[]' 2>/dev/null)

    if [ -z "$events" ]; then
        error "No hooks found in configuration"
        return 1
    fi

    for event in $events; do
        # Check if event is valid
        local valid=false
        for valid_event in "${VALID_HOOK_EVENTS[@]}"; do
            if [ "$event" == "$valid_event" ]; then
                valid=true
                break
            fi
        done

        if [ "$valid" == "false" ]; then
            # Check if it's a known invalid event
            for invalid_event in "${INVALID_HOOK_EVENTS[@]}"; do
                if [ "$event" == "$invalid_event" ]; then
                    error "Invalid hook event '$event' - this event does NOT exist!"
                    error "Did you mean 'PreToolUse' or 'PostToolUse'?"
                    ((errors++))
                    continue 2
                fi
            done
            error "Unknown hook event '$event'"
            error "Valid events: ${VALID_HOOK_EVENTS[*]}"
            ((errors++))
            continue
        fi

        # Check structure: should have array of objects with nested 'hooks' array
        local hook_configs=$(echo "$content" | jq -r ".hooks[\"$event\"]")

        if ! echo "$hook_configs" | jq -e 'type == "array"' > /dev/null 2>&1; then
            error "Event '$event' should have an array value"
            ((errors++))
            continue
        fi

        # Check each hook configuration
        local num_configs=$(echo "$hook_configs" | jq 'length')
        for ((i=0; i<num_configs; i++)); do
            local config=$(echo "$hook_configs" | jq ".[$i]")

            # Check for nested 'hooks' array (new format)
            if ! echo "$config" | jq -e '.hooks' > /dev/null 2>&1; then
                error "Event '$event' config #$((i+1)): missing nested 'hooks' array"
                error "Correct format: {\"matcher\": \"...\", \"hooks\": [{\"type\": \"command\", \"command\": \"...\"}]}"
                ((errors++))
                continue
            fi

            # Check each nested hook
            local nested_hooks=$(echo "$config" | jq '.hooks')
            local num_nested=$(echo "$nested_hooks" | jq 'length')

            for ((j=0; j<num_nested; j++)); do
                local hook=$(echo "$nested_hooks" | jq ".[$j]")
                local hook_type=$(echo "$hook" | jq -r '.type // "command"')

                # Validate type
                local valid_type=false
                for vt in "${VALID_HOOK_TYPES[@]}"; do
                    if [ "$hook_type" == "$vt" ]; then
                        valid_type=true
                        break
                    fi
                done

                if [ "$valid_type" == "false" ]; then
                    error "Event '$event' hook type '$hook_type' is invalid"
                    error "Valid types: ${VALID_HOOK_TYPES[*]}"
                    ((errors++))
                fi

                # Check command exists for command type
                if [ "$hook_type" == "command" ]; then
                    local cmd=$(echo "$hook" | jq -r '.command // empty')
                    if [ -z "$cmd" ]; then
                        error "Event '$event' command hook missing 'command' field"
                        ((errors++))
                    fi
                fi

                # Check prompt exists for prompt/agent type
                if [ "$hook_type" == "prompt" ] || [ "$hook_type" == "agent" ]; then
                    local prompt=$(echo "$hook" | jq -r '.prompt // empty')
                    if [ -z "$prompt" ]; then
                        error "Event '$event' $hook_type hook missing 'prompt' field"
                        ((errors++))
                    fi
                fi
            done
        done
    done

    return $errors
}

validate_skill() {
    local content="$1"
    local errors=0

    # Check YAML frontmatter
    if ! echo "$content" | grep -q "^---"; then
        error "Skill missing YAML frontmatter (must start with ---)"
        return 1
    fi

    # Extract frontmatter
    local frontmatter=$(echo "$content" | sed -n '/^---$/,/^---$/p' | sed '1d;$d')

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
        error "Skill missing required 'name' field in frontmatter"
        ((errors++))
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        error "Skill missing required 'description' field in frontmatter"
        ((errors++))
    fi

    # Validate disable-model-invocation if present
    local dmi=$(echo "$frontmatter" | grep "^disable-model-invocation:" | cut -d: -f2 | tr -d ' ')
    if [ -n "$dmi" ] && [ "$dmi" != "true" ] && [ "$dmi" != "false" ]; then
        error "disable-model-invocation must be 'true' or 'false', got '$dmi'"
        ((errors++))
    fi

    return $errors
}

validate_subagent() {
    local content="$1"
    local errors=0

    # Check YAML frontmatter
    if ! echo "$content" | grep -q "^---"; then
        error "Subagent missing YAML frontmatter (must start with ---)"
        return 1
    fi

    # Extract frontmatter
    local frontmatter=$(echo "$content" | sed -n '/^---$/,/^---$/p' | sed '1d;$d')

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
        error "Subagent missing required 'name' field in frontmatter"
        ((errors++))
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        error "Subagent missing required 'description' field in frontmatter"
        ((errors++))
    fi

    # Validate model if present
    local model=$(echo "$frontmatter" | grep "^model:" | cut -d: -f2 | tr -d ' ')
    if [ -n "$model" ]; then
        local valid_model=false
        for vm in "${VALID_MODELS[@]}"; do
            if [ "$model" == "$vm" ]; then
                valid_model=true
                break
            fi
        done
        if [ "$valid_model" == "false" ]; then
            error "Invalid model '$model'. Valid: ${VALID_MODELS[*]}"
            ((errors++))
        fi
    fi

    # Validate tools if present
    local tools=$(echo "$frontmatter" | grep "^tools:" | cut -d: -f2)
    if [ -n "$tools" ]; then
        IFS=',' read -ra tool_array <<< "$tools"
        for tool in "${tool_array[@]}"; do
            tool=$(echo "$tool" | tr -d ' ')
            local valid_tool=false
            for vt in "${VALID_TOOLS[@]}"; do
                if [ "$tool" == "$vt" ]; then
                    valid_tool=true
                    break
                fi
            done
            if [ "$valid_tool" == "false" ]; then
                error "Invalid tool '$tool'. Valid: ${VALID_TOOLS[*]}"
                ((errors++))
            fi
        done
    fi

    return $errors
}

validate_permissions() {
    local content="$1"
    local errors=0

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed"
        exit 1
    fi

    # Parse JSON
    if ! echo "$content" | jq . > /dev/null 2>&1; then
        error "Invalid JSON format"
        return 1
    fi

    # Check structure
    if ! echo "$content" | jq -e '.permissions' > /dev/null 2>&1; then
        error "Missing 'permissions' key"
        return 1
    fi

    # Validate allow array
    local allow=$(echo "$content" | jq -r '.permissions.allow // empty')
    if [ -n "$allow" ] && ! echo "$allow" | jq -e 'type == "array"' > /dev/null 2>&1; then
        error "'allow' must be an array"
        ((errors++))
    fi

    # Validate deny array
    local deny=$(echo "$content" | jq -r '.permissions.deny // empty')
    if [ -n "$deny" ] && ! echo "$deny" | jq -e 'type == "array"' > /dev/null 2>&1; then
        error "'deny' must be an array"
        ((errors++))
    fi

    return $errors
}

validate_custom_commands() {
    local content="$1"
    local errors=0

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed"
        exit 1
    fi

    # Parse JSON
    if ! echo "$content" | jq . > /dev/null 2>&1; then
        error "Invalid JSON format"
        return 1
    fi

    # Check structure
    if ! echo "$content" | jq -e '.customCommands' > /dev/null 2>&1; then
        error "Missing 'customCommands' key"
        return 1
    fi

    # Validate each command is a string
    local commands=$(echo "$content" | jq -r '.customCommands | to_entries[] | "\(.key):\(.value | type)"')
    while IFS=: read -r name type; do
        if [ "$type" != "string" ]; then
            error "Command '$name' value must be a string, got $type"
            ((errors++))
        fi
    done <<< "$commands"

    return $errors
}

# Main
if [ $# -lt 2 ]; then
    usage
fi

TYPE="$1"
INPUT="$2"

# Read content
if [ "$INPUT" == "-" ]; then
    CONTENT=$(cat)
elif [ -f "$INPUT" ]; then
    CONTENT=$(cat "$INPUT")
else
    CONTENT="$INPUT"
fi

# Validate based on type
case "$TYPE" in
    hooks)
        if validate_hooks "$CONTENT"; then
            success "Hook configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    skill)
        if validate_skill "$CONTENT"; then
            success "Skill configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    subagent)
        if validate_subagent "$CONTENT"; then
            success "Subagent configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    permissions)
        if validate_permissions "$CONTENT"; then
            success "Permissions configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    custom-commands)
        if validate_custom_commands "$CONTENT"; then
            success "Custom commands configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    *)
        error "Unknown type: $TYPE"
        usage
        ;;
esac
