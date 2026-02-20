#!/bin/bash
#
# validate-config.sh - Validate Claude Code configurations against schemas
#
# Usage: ./validate-config.sh <type> <content>
#   type: hooks | skill | subagent | permissions | custom-commands | mcp-servers | lsp-servers | agent-team
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
    echo "Types: hooks, skill, subagent, permissions, custom-commands, mcp-servers, lsp-servers, agent-team"
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
    "TeammateIdle"
    "TaskCompleted"
    "ConfigChange"
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
VALID_TOOLS=("Read" "Grep" "Glob" "Bash" "Edit" "Write" "WebFetch" "WebSearch" "Task" "NotebookEdit" "AskUserQuestion" "TaskOutput" "ExitPlanMode" "MCPSearch")

# Valid models
VALID_MODELS=("opus" "sonnet" "haiku" "inherit")

# Valid MCP server types
VALID_MCP_TYPES=("stdio" "sse")

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

    # Validate context if present
    local ctx=$(echo "$frontmatter" | grep "^context:" | cut -d: -f2 | tr -d ' ')
    if [ -n "$ctx" ] && [ "$ctx" != "fork" ]; then
        error "context must be 'fork', got '$ctx'"
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
            # Allow MCP tools (mcp__*) without validation
            if [[ "$tool" == mcp__* ]]; then
                continue
            fi
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

    # Validate permissionMode if present
    local pm=$(echo "$frontmatter" | grep "^permissionMode:" | cut -d: -f2 | tr -d ' ')
    if [ -n "$pm" ]; then
        local valid_pm=false
        for vpm in "default" "acceptEdits" "dontAsk" "bypassPermissions" "plan"; do
            if [ "$pm" == "$vpm" ]; then
                valid_pm=true
                break
            fi
        done
        if [ "$valid_pm" == "false" ]; then
            error "Invalid permissionMode '$pm'. Valid: default, acceptEdits, dontAsk, bypassPermissions, plan"
            ((errors++))
        fi
    fi

    # Validate memory if present
    local mem=$(echo "$frontmatter" | grep "^memory:" | cut -d: -f2 | tr -d ' ')
    if [ -n "$mem" ]; then
        local valid_mem=false
        for vmem in "user" "project" "local"; do
            if [ "$mem" == "$vmem" ]; then
                valid_mem=true
                break
            fi
        done
        if [ "$valid_mem" == "false" ]; then
            error "Invalid memory scope '$mem'. Valid: user, project, local"
            ((errors++))
        fi
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

validate_mcp_servers() {
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

    # Check for mcpServers key
    if ! echo "$content" | jq -e '.mcpServers' > /dev/null 2>&1; then
        error "Missing 'mcpServers' key"
        return 1
    fi

    # Validate each server
    local servers=$(echo "$content" | jq -r '.mcpServers | keys[]' 2>/dev/null)
    for server in $servers; do
        local server_config=$(echo "$content" | jq ".mcpServers[\"$server\"]")

        # Check type field
        local server_type=$(echo "$server_config" | jq -r '.type // empty')
        if [ -z "$server_type" ]; then
            error "Server '$server' missing 'type' field (must be 'stdio' or 'sse')"
            ((errors++))
            continue
        fi

        local valid_type=false
        for vt in "${VALID_MCP_TYPES[@]}"; do
            if [ "$server_type" == "$vt" ]; then
                valid_type=true
                break
            fi
        done
        if [ "$valid_type" == "false" ]; then
            error "Server '$server' has invalid type '$server_type'. Valid: ${VALID_MCP_TYPES[*]}"
            ((errors++))
        fi

        # Check required fields by type
        if [ "$server_type" == "stdio" ]; then
            local cmd=$(echo "$server_config" | jq -r '.command // empty')
            if [ -z "$cmd" ]; then
                error "Server '$server' (stdio) missing 'command' field"
                ((errors++))
            fi
        elif [ "$server_type" == "sse" ]; then
            local url=$(echo "$server_config" | jq -r '.url // empty')
            if [ -z "$url" ]; then
                error "Server '$server' (sse) missing 'url' field"
                ((errors++))
            fi
        fi
    done

    return $errors
}

validate_lsp_servers() {
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

    # Validate each server (top-level keys are server names)
    local servers=$(echo "$content" | jq -r 'keys[]' 2>/dev/null)
    if [ -z "$servers" ]; then
        error "No LSP servers found in configuration"
        return 1
    fi

    for server in $servers; do
        # Skip _template metadata
        if [ "$server" == "_template" ]; then
            continue
        fi

        local server_config=$(echo "$content" | jq ".[\"$server\"]")

        # Check command field
        local cmd=$(echo "$server_config" | jq -r '.command // empty')
        if [ -z "$cmd" ]; then
            error "Server '$server' missing 'command' field"
            ((errors++))
        fi

        # Check languages field
        if ! echo "$server_config" | jq -e '.languages' > /dev/null 2>&1; then
            error "Server '$server' missing 'languages' field"
            ((errors++))
        elif ! echo "$server_config" | jq -e '.languages | type == "array"' > /dev/null 2>&1; then
            error "Server '$server' 'languages' must be an array"
            ((errors++))
        fi
    done

    return $errors
}

validate_agent_team() {
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

    # Check required fields
    local name=$(echo "$content" | jq -r '.name // empty')
    if [ -z "$name" ]; then
        error "Missing 'name' field"
        ((errors++))
    fi

    local desc=$(echo "$content" | jq -r '.description // empty')
    if [ -z "$desc" ]; then
        error "Missing 'description' field"
        ((errors++))
    fi

    # Check agents array
    if ! echo "$content" | jq -e '.agents' > /dev/null 2>&1; then
        error "Missing 'agents' array"
        return 1
    fi

    if ! echo "$content" | jq -e '.agents | type == "array"' > /dev/null 2>&1; then
        error "'agents' must be an array"
        return 1
    fi

    local num_agents=$(echo "$content" | jq '.agents | length')
    if [ "$num_agents" -lt 1 ]; then
        error "Agent team must have at least 1 agent"
        ((errors++))
    fi

    # Validate each agent
    for ((i=0; i<num_agents; i++)); do
        local agent=$(echo "$content" | jq ".agents[$i]")

        local agent_name=$(echo "$agent" | jq -r '.name // empty')
        if [ -z "$agent_name" ]; then
            error "Agent #$((i+1)) missing 'name' field"
            ((errors++))
        fi

        local agent_role=$(echo "$agent" | jq -r '.role // empty')
        if [ -z "$agent_role" ]; then
            error "Agent #$((i+1)) missing 'role' field"
            ((errors++))
        fi

        # Validate model if present
        local agent_model=$(echo "$agent" | jq -r '.model // empty')
        if [ -n "$agent_model" ]; then
            local valid_model=false
            for vm in "${VALID_MODELS[@]}"; do
                if [ "$agent_model" == "$vm" ]; then
                    valid_model=true
                    break
                fi
            done
            if [ "$valid_model" == "false" ]; then
                error "Agent '$agent_name' has invalid model '$agent_model'. Valid: ${VALID_MODELS[*]}"
                ((errors++))
            fi
        fi
    done

    # Validate settings if present
    local display_mode=$(echo "$content" | jq -r '.settings.displayMode // empty')
    if [ -n "$display_mode" ] && [ "$display_mode" != "in-process" ] && [ "$display_mode" != "split-panes" ]; then
        error "Invalid displayMode '$display_mode'. Valid: in-process, split-panes"
        ((errors++))
    fi

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
    mcp-servers)
        if validate_mcp_servers "$CONTENT"; then
            success "MCP server configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    lsp-servers)
        if validate_lsp_servers "$CONTENT"; then
            success "LSP server configuration is valid"
            exit 0
        else
            exit 1
        fi
        ;;
    agent-team)
        if validate_agent_team "$CONTENT"; then
            success "Agent team configuration is valid"
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
