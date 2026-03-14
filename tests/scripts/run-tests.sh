#!/bin/bash
# Main test runner for claude-code-automation
#
# Usage:
#   ./run-tests.sh              # Run all tests (structure + fixture)
#   ./run-tests.sh structure    # Run only structure tests (fast, no Claude)
#   ./run-tests.sh e2e          # Run only fixture tests (fast, no Claude)
#   ./run-tests.sh fixture      # Same as e2e
#   ./run-tests.sh interactive  # Run interactive tests (slow, uses Claude, costs tokens)
#   ./run-tests.sh full         # Run all tests including interactive
#   ./run-tests.sh TEST-01      # Run specific test

# Don't exit on error - we want to continue running tests
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load helpers
source "$SCRIPT_DIR/helpers.sh"

# Parse arguments
TEST_TYPE="${1:-all}"

log_section "claude-code-automation Test Suite"
log_info "Project root: $PROJECT_ROOT"
log_info "Test type: $TEST_TYPE"

# ============================================
# STRUCTURE TESTS (Fast, no Claude needed)
# ============================================
run_structure_tests() {
    log_section "Structure Tests"

    # Test: Plugin structure is valid
    log_info "Testing plugin structure..."

    # Check for marketplace.json (required for plugin marketplace)
    assert_file_exists "$PROJECT_ROOT/.claude-plugin/marketplace.json" \
        "STRUCT-01: marketplace.json exists"

    assert_file_exists "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        "STRUCT-02: plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "STRUCT-03: SKILL.md exists"

    # Test: JSON files are valid
    log_info "Testing JSON validity..."

    assert_valid_json "$PROJECT_ROOT/.claude-plugin/marketplace.json" \
        "STRUCT-04: marketplace.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        "STRUCT-05: plugin.json is valid JSON"

    # Test: SKILL.md has valid frontmatter
    log_info "Testing SKILL.md frontmatter..."

    assert_valid_frontmatter "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "STRUCT-06: SKILL.md has valid frontmatter"

    # Test: Required fields in plugin.json
    log_info "Testing required fields..."

    assert_json_has_key "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        ".name" "STRUCT-07: plugin.json has name"

    assert_json_has_key "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        ".version" "STRUCT-08: plugin.json has version"

    assert_json_has_key "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        ".description" "STRUCT-09: plugin.json has description"

    # Test: SKILL.md contains required sections
    log_info "Testing SKILL.md content..."

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "disable-model-invocation" "STRUCT-10: SKILL.md has disable-model-invocation"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "AskUserQuestion" "STRUCT-11: SKILL.md references AskUserQuestion"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        '\$ARGUMENTS' "STRUCT-12: SKILL.md uses \$ARGUMENTS"

    # Test: Decision matrix is present
    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "Hook.*Skill.*Subagent" "STRUCT-13: SKILL.md has decision matrix"

    # Test: All automation types are documented
    for type in "Hook" "Skill" "Subagent" "Permissions" "CLAUDE.md" "Custom"; do
        assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
            "$type" "STRUCT-14: SKILL.md documents $type"
    done

    # Test: New schema files exist
    log_info "Testing new schema files..."

    assert_file_exists "$PROJECT_ROOT/plugin/schemas/mcp-servers.json" \
        "STRUCT-15: mcp-servers.json schema exists"

    assert_file_exists "$PROJECT_ROOT/plugin/schemas/lsp-servers.json" \
        "STRUCT-16: lsp-servers.json schema exists"

    assert_file_exists "$PROJECT_ROOT/plugin/schemas/agent-teams.json" \
        "STRUCT-17: agent-teams.json schema exists"

    # Test: New schema files are valid JSON
    log_info "Testing new schema JSON validity..."

    assert_valid_json "$PROJECT_ROOT/plugin/schemas/mcp-servers.json" \
        "STRUCT-18: mcp-servers.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugin/schemas/lsp-servers.json" \
        "STRUCT-19: lsp-servers.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugin/schemas/agent-teams.json" \
        "STRUCT-20: agent-teams.json is valid JSON"

    # Test: SKILL.md documents new automation types
    log_info "Testing SKILL.md documents new types..."

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "MCP Server" "STRUCT-21: SKILL.md documents MCP Server"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "LSP Server" "STRUCT-22: SKILL.md documents LSP Server"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "Agent Team" "STRUCT-23: SKILL.md documents Agent Team"

    # ============================================
    # FIXTURE VALIDATION (validate-config.sh)
    # ============================================
    log_info "Validating fixtures against schemas..."

    local VALIDATE="$PROJECT_ROOT/plugin/scripts/validate-config.sh"
    chmod +x "$VALIDATE"

    assert_validation_passes "$VALIDATE" hooks \
        "$PROJECT_ROOT/tests/fixtures/hook-only.json" \
        "STRUCT-24: hook fixture passes validation"

    assert_validation_passes "$VALIDATE" skill \
        "$PROJECT_ROOT/tests/fixtures/skill-auto.md" \
        "STRUCT-25: skill-auto fixture passes validation"

    assert_validation_passes "$VALIDATE" skill \
        "$PROJECT_ROOT/tests/fixtures/skill-manual.md" \
        "STRUCT-26: skill-manual fixture passes validation"

    assert_validation_passes "$VALIDATE" subagent \
        "$PROJECT_ROOT/tests/fixtures/subagent.md" \
        "STRUCT-27: subagent fixture passes validation"

    assert_validation_passes "$VALIDATE" permissions \
        "$PROJECT_ROOT/tests/fixtures/permissions.json" \
        "STRUCT-28: permissions fixture passes validation"

    assert_validation_passes "$VALIDATE" custom-commands \
        "$PROJECT_ROOT/tests/fixtures/custom-command.json" \
        "STRUCT-29: custom-command fixture passes validation"

    assert_validation_passes "$VALIDATE" mcp-servers \
        "$PROJECT_ROOT/tests/fixtures/mcp-server.json" \
        "STRUCT-30: mcp-server fixture passes validation"

    assert_validation_passes "$VALIDATE" lsp-servers \
        "$PROJECT_ROOT/tests/fixtures/lsp-server.json" \
        "STRUCT-31: lsp-server fixture passes validation"

    assert_validation_passes "$VALIDATE" agent-team \
        "$PROJECT_ROOT/tests/fixtures/agent-team.json" \
        "STRUCT-32: agent-team fixture passes validation"

    # ============================================
    # VERSION SYNC
    # ============================================
    log_info "Testing version sync..."

    local ver_file=$(cat "$PROJECT_ROOT/VERSION" | tr -d '[:space:]')
    local ver_plugin=$(jq -r '.version' "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json")
    local ver_market=$(jq -r '.plugins[0].version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")

    if [ "$ver_file" == "$ver_plugin" ] && [ "$ver_file" == "$ver_market" ]; then
        log_success "STRUCT-33: version sync — all files show $ver_file"
    else
        log_fail "STRUCT-33: version mismatch — VERSION=$ver_file, plugin.json=$ver_plugin, marketplace.json=$ver_market"
    fi

    # ============================================
    # NEGATIVE VALIDATION (invalid configs must fail)
    # ============================================
    log_info "Testing negative validation (invalid configs rejected)..."

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreBash":[{"hooks":[{"type":"command","command":"echo test"}]}]}}' \
        "STRUCT-34: reject invalid hook event (PreBash)"

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"command":"echo test"}]}}' \
        "STRUCT-35: reject hook missing nested hooks array"

    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nmodel: gpt4\n---\nContent')" \
        "STRUCT-36: reject subagent with invalid model"

    assert_validation_fails "$VALIDATE" mcp-servers \
        '{"mcpServers":{"test":{"type":"websocket","command":"test"}}}' \
        "STRUCT-37: reject MCP server with invalid type"

    assert_validation_fails "$VALIDATE" lsp-servers \
        '{"typescript":{"command":"tsc"}}' \
        "STRUCT-38: reject LSP server missing languages"

    assert_validation_fails "$VALIDATE" agent-team \
        '{"name":"test","description":"test"}' \
        "STRUCT-39: reject agent team missing agents array"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"TeammateIdle":[{"hooks":[{"type":"command","command":"exit 2"}]}]}}' \
        "STRUCT-40: accept TeammateIdle hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"TaskCompleted":[{"hooks":[{"type":"command","command":"exit 2"}]}]}}' \
        "STRUCT-41: accept TaskCompleted hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"ConfigChange":[{"matcher":"user_settings","hooks":[{"type":"command","command":"echo changed"}]}]}}' \
        "STRUCT-42: accept ConfigChange hook event"

    # ============================================
    # NEW EVENT TESTS (v2.2+)
    # ============================================
    log_info "Testing new hook events..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"PostCompact":[{"hooks":[{"type":"command","command":"echo compacted"}]}]}}' \
        "STRUCT-43: accept PostCompact hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"InstructionsLoaded":[{"hooks":[{"type":"command","command":"echo loaded"}]}]}}' \
        "STRUCT-44: accept InstructionsLoaded hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"WorktreeCreate":[{"hooks":[{"type":"command","command":"echo /tmp/wt"}]}]}}' \
        "STRUCT-45: accept WorktreeCreate hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"WorktreeRemove":[{"hooks":[{"type":"command","command":"echo cleanup"}]}]}}' \
        "STRUCT-46: accept WorktreeRemove hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"Elicitation":[{"matcher":"myserver","hooks":[{"type":"command","command":"exit 0"}]}]}}' \
        "STRUCT-47: accept Elicitation hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"ElicitationResult":[{"hooks":[{"type":"command","command":"exit 0"}]}]}}' \
        "STRUCT-48: accept ElicitationResult hook event"

    # ============================================
    # HTTP HOOK TYPE TESTS
    # ============================================
    log_info "Testing http hook type..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"http","url":"https://example.com/hook"}]}]}}' \
        "STRUCT-49: accept http hook type"

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"hooks":[{"type":"http"}]}]}}' \
        "STRUCT-50: reject http hook missing url"

    # ============================================
    # NEW TOOL VALIDATION TESTS
    # ============================================
    log_info "Testing new subagent tools..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Agent, Read, Glob\n---\nContent')" \
        "STRUCT-51: accept Agent tool in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: TaskCreate, TaskUpdate, ToolSearch\n---\nContent')" \
        "STRUCT-52: accept new task/search tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: CronCreate, CronList, CronDelete\n---\nContent')" \
        "STRUCT-53: accept Cron tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: EnterWorktree, ExitWorktree, EnterPlanMode\n---\nContent')" \
        "STRUCT-54: accept Worktree and PlanMode tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: LSP, ListMcpResourcesTool, ReadMcpResourceTool\n---\nContent')" \
        "STRUCT-55: accept LSP and MCP resource tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Agent(worker, researcher), Read\n---\nContent')" \
        "STRUCT-56: accept Agent(type) syntax in subagent tools"

    # ============================================
    # NEW SUBAGENT FIELD VALIDATION TESTS
    # ============================================
    log_info "Testing new subagent frontmatter fields..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nbackground: true\n---\nContent')" \
        "STRUCT-57: accept background field in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nisolation: worktree\n---\nContent')" \
        "STRUCT-58: accept isolation: worktree in subagent"

    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nisolation: docker\n---\nContent')" \
        "STRUCT-59: reject invalid isolation value"

    # ============================================
    # NEW MCP SERVER TYPE TESTS
    # ============================================
    log_info "Testing http MCP server type..."

    assert_validation_passes "$VALIDATE" mcp-servers \
        '{"mcpServers":{"remote":{"type":"http","url":"https://mcp.example.com/mcp"}}}' \
        "STRUCT-60: accept http MCP server type"

    assert_validation_fails "$VALIDATE" mcp-servers \
        '{"mcpServers":{"remote":{"type":"http"}}}' \
        "STRUCT-61: reject http MCP server missing url"

    # ============================================
    # SKILL VALIDATION TESTS
    # ============================================
    log_info "Testing new skill frontmatter fields..."

    assert_validation_passes "$VALIDATE" skill \
        "$(printf -- '---\nname: test\ndescription: test\nuser-invocable: false\n---\nContent')" \
        "STRUCT-62: accept user-invocable field in skill"

    assert_validation_fails "$VALIDATE" skill \
        "$(printf -- '---\nname: test\ndescription: test\nuser-invocable: maybe\n---\nContent')" \
        "STRUCT-63: reject invalid user-invocable value"

    # ============================================
    # SCHEMA CONTENT TESTS
    # ============================================
    log_info "Testing schema contents are up-to-date..."

    # Verify hooks schema has all 21 events
    local hook_events=$(jq '.validEvents | length' "$PROJECT_ROOT/plugin/schemas/hooks.json")
    if [ "$hook_events" -eq 21 ]; then
        log_success "STRUCT-64: hooks schema has 21 events"
    else
        log_fail "STRUCT-64: hooks schema has $hook_events events (expected 21)"
    fi

    # Verify hooks schema has http type
    assert_file_contains "$PROJECT_ROOT/plugin/schemas/hooks.json" \
        '"http"' "STRUCT-65: hooks schema includes http type"

    # Verify subagent schema has Agent tool
    assert_file_contains "$PROJECT_ROOT/plugin/schemas/subagents.json" \
        '"Agent"' "STRUCT-66: subagent schema includes Agent tool"

    # Verify subagent schema has new fields
    assert_file_contains "$PROJECT_ROOT/plugin/schemas/subagents.json" \
        '"maxTurns"' "STRUCT-67: subagent schema has maxTurns field"

    assert_file_contains "$PROJECT_ROOT/plugin/schemas/subagents.json" \
        '"isolation"' "STRUCT-68: subagent schema has isolation field"

    # Verify MCP schema has http type
    assert_file_contains "$PROJECT_ROOT/plugin/schemas/mcp-servers.json" \
        '"http"' "STRUCT-69: MCP schema includes http type"

    # Verify skills schema has new fields
    assert_file_contains "$PROJECT_ROOT/plugin/schemas/skills.json" \
        '"user-invocable"' "STRUCT-70: skills schema has user-invocable field"

    assert_file_contains "$PROJECT_ROOT/plugin/schemas/skills.json" \
        '"allowed-tools"' "STRUCT-71: skills schema has allowed-tools field"

    assert_file_contains "$PROJECT_ROOT/plugin/schemas/skills.json" \
        '"agent"' "STRUCT-72: skills schema has agent field"

    # ============================================
    # JSON GUARD SCRIPT TESTS
    # ============================================
    log_info "Testing JSON config guard script..."

    local GUARD="$PROJECT_ROOT/plugin/scripts/guard-json-config.sh"
    chmod +x "$GUARD"

    # Test: valid JSON Write to settings.json → allow
    local result
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/.claude/settings.json","content":"{\"hooks\":{}}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 0 ]; then
        log_success "STRUCT-73: guard allows valid JSON write to settings.json"
    else
        log_fail "STRUCT-73: guard should allow valid JSON write (got exit $guard_exit)"
    fi

    # Test: invalid JSON Write to settings.json → block
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/.claude/settings.json","content":"{\"hooks\":{},}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-74: guard blocks invalid JSON write to settings.json"
    else
        log_fail "STRUCT-74: guard should block invalid JSON write (got exit $guard_exit)"
    fi

    # Test: any file Write that is NOT a config file → allow silently
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/random.json","content":"not json"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 0 ]; then
        log_success "STRUCT-75: guard ignores non-config files"
    else
        log_fail "STRUCT-75: guard should ignore non-config files (got exit $guard_exit)"
    fi

    # Test: invalid JSON Write to .mcp.json → block
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/project/.mcp.json","content":"{\"mcpServers\":{\"x\":{\"type\":\"stdio\"}},,}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-76: guard blocks invalid JSON write to .mcp.json"
    else
        log_fail "STRUCT-76: guard should block invalid .mcp.json write (got exit $guard_exit)"
    fi

    # Test: invalid JSON Edit on settings.json → catch
    mkdir -p /tmp/guard-test/.claude
    echo '{"broken":}' > /tmp/guard-test/.claude/settings.json
    result=$(echo '{"hook_event_name":"PostToolUse","tool_input":{"file_path":"/tmp/guard-test/.claude/settings.json"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    rm -rf /tmp/guard-test
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-77: guard catches invalid JSON after edit on settings.json"
    else
        log_fail "STRUCT-77: guard should catch invalid JSON after edit (got exit $guard_exit)"
    fi

    # Test: SKILL.md has guard hooks in frontmatter
    assert_file_contains "$PROJECT_ROOT/plugin/skills/automate/SKILL.md" \
        "guard-json-config.sh" "STRUCT-78: SKILL.md has JSON guard hooks"
}

# ============================================
# FIXTURE TESTS (no Claude needed)
# ============================================
run_fixture_tests() {
    log_section "Fixture Tests"

    # Setup
    setup_sandbox
    backup_global_config

    # Trap to ensure cleanup on exit
    trap restore_global_config EXIT

    # Run individual fixture tests
    run_fixture_test_01
    run_fixture_test_02
    run_fixture_test_03
    run_fixture_test_04
    run_fixture_test_05
    run_fixture_test_06

    # Cleanup
    cleanup_sandbox
    restore_global_config
    trap - EXIT
}

# Fixture TEST-01: Hook creation
run_fixture_test_01() {
    log_info "Fixture TEST-01: Hook creation"

    local settings_file="$SANDBOX_DIR/.claude/settings.json"

    # Create expected output for verification
    mkdir -p "$SANDBOX_DIR/.claude"
    cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if cat | jq -r '.tool_input.command' | grep -q 'git push'; then echo 'Push blocked' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
EOF

    # Verify structure
    assert_valid_json "$settings_file" "FIX-01a: settings.json is valid"
    assert_json_has_key "$settings_file" ".hooks" "FIX-01b: has hooks key"
    assert_json_has_key "$settings_file" ".hooks.PreToolUse" "FIX-01c: has PreToolUse hook"
}

# Fixture TEST-02: Skill creation
run_fixture_test_02() {
    log_info "Fixture TEST-02: Skill creation"

    local skill_dir="$SANDBOX_DIR/.claude/skills/api-conventions"
    local skill_file="$skill_dir/SKILL.md"

    # Create expected output
    mkdir -p "$skill_dir"
    cat > "$skill_file" << 'EOF'
---
name: api-conventions
description: REST API naming conventions
disable-model-invocation: false
---

# API Conventions

Apply these conventions when working with API code:

- Use kebab-case for URL paths
- Use camelCase for JSON properties
- Always include pagination for list endpoints
EOF

    # Verify structure
    assert_file_exists "$skill_file" "FIX-02a: SKILL.md created"
    assert_valid_frontmatter "$skill_file" "FIX-02b: valid frontmatter"
    assert_file_contains "$skill_file" "disable-model-invocation: false" "FIX-02c: auto-invocation enabled"
}

# Fixture TEST-03: Subagent creation
run_fixture_test_03() {
    log_info "Fixture TEST-03: Subagent creation"

    local agent_file="$SANDBOX_DIR/.claude/agents/code-reviewer.md"

    # Create expected output
    mkdir -p "$SANDBOX_DIR/.claude/agents"
    cat > "$agent_file" << 'EOF'
---
name: code-reviewer
description: Independent code review with clean context
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are an independent code reviewer. Review code for:
- Logic errors
- Security issues
- Performance problems
- Code style violations

Provide specific line references and suggested fixes.
EOF

    # Verify structure
    assert_file_exists "$agent_file" "FIX-03a: agent file created"
    assert_valid_frontmatter "$agent_file" "FIX-03b: valid frontmatter"
    assert_file_contains "$agent_file" "tools:" "FIX-03c: has tools definition"
    assert_file_contains "$agent_file" "model:" "FIX-03d: has model definition"
}

# Fixture TEST-04: MCP server creation
run_fixture_test_04() {
    log_info "Fixture TEST-04: MCP server creation"

    local mcp_file="$SANDBOX_DIR/.mcp.json"

    # Create expected output
    cat > "$mcp_file" << 'EOF'
{
  "mcpServers": {
    "my-tools": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@my-org/my-mcp-server"],
      "env": {
        "API_KEY": "test-key"
      }
    }
  }
}
EOF

    # Verify structure
    assert_valid_json "$mcp_file" "FIX-04a: .mcp.json is valid JSON"
    assert_json_has_key "$mcp_file" ".mcpServers" "FIX-04b: has mcpServers key"
    assert_json_has_key "$mcp_file" '.mcpServers."my-tools".type' "FIX-04c: server has type field"
}

# Fixture TEST-05: LSP server creation
run_fixture_test_05() {
    log_info "Fixture TEST-05: LSP server creation"

    local lsp_file="$SANDBOX_DIR/.lsp.json"

    # Create expected output (flat format — server name as root key)
    cat > "$lsp_file" << 'EOF'
{
  "typescript": {
    "command": "typescript-language-server",
    "args": ["--stdio"],
    "languages": ["typescript", "javascript"]
  }
}
EOF

    # Verify structure
    assert_valid_json "$lsp_file" "FIX-05a: .lsp.json is valid JSON"
    assert_json_has_key "$lsp_file" ".typescript.command" "FIX-05b: server has command field"
    assert_json_has_key "$lsp_file" ".typescript.languages" "FIX-05c: server has languages field"
}

# Fixture TEST-06: Agent team creation
run_fixture_test_06() {
    log_info "Fixture TEST-06: Agent team creation"

    local team_dir="$SANDBOX_DIR/.claude/teams/dev-team"
    local team_file="$team_dir/config.json"

    # Create expected output (agents use "role" field)
    mkdir -p "$team_dir"
    cat > "$team_file" << 'EOF'
{
  "name": "dev-team",
  "description": "Development team for parallel feature work",
  "agents": [
    {
      "name": "frontend",
      "role": "Handles UI components",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    },
    {
      "name": "backend",
      "role": "Handles API endpoints",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    }
  ],
  "settings": {
    "displayMode": "in-process",
    "delegateMode": false,
    "requirePlanApproval": true
  }
}
EOF

    # Verify structure
    assert_valid_json "$team_file" "FIX-06a: team config.json is valid JSON"
    assert_json_has_key "$team_file" ".name" "FIX-06b: has name field"
    assert_json_has_key "$team_file" ".description" "FIX-06c: has description field"
    assert_json_has_key "$team_file" ".agents" "FIX-06d: has agents array"
}

# ============================================
# SPECIFIC TEST RUNNER
# ============================================
run_specific_test() {
    local test_id="$1"
    log_section "Running specific test: $test_id"

    case "$test_id" in
        TEST-01) run_fixture_test_01 ;;
        TEST-02) run_fixture_test_02 ;;
        TEST-03) run_fixture_test_03 ;;
        TEST-04) run_fixture_test_04 ;;
        TEST-05) run_fixture_test_05 ;;
        TEST-06) run_fixture_test_06 ;;
        STRUCT-*) run_structure_tests ;;
        *)
            log_fail "Unknown test: $test_id"
            echo "Available tests: TEST-01..06, STRUCT-*"
            exit 1
            ;;
    esac
}

# ============================================
# INTERACTIVE TESTS (runs actual Claude)
# ============================================
run_interactive_tests() {
    log_section "Interactive Tests (uses Claude, costs tokens)"
    log_info "Running tests that use actual Claude commands..."
    log_info "This will consume tokens and may take several minutes."

    if [ -x "$SCRIPT_DIR/e2e-interactive.sh" ]; then
        "$SCRIPT_DIR/e2e-interactive.sh" all
    else
        log_fail "e2e-interactive.sh not found or not executable"
    fi
}

# ============================================
# MAIN
# ============================================
main() {
    case "$TEST_TYPE" in
        all)
            run_structure_tests
            run_fixture_tests
            ;;
        structure)
            run_structure_tests
            ;;
        e2e|fixture)
            run_fixture_tests
            ;;
        interactive)
            run_interactive_tests
            ;;
        full)
            run_structure_tests
            run_fixture_tests
            run_interactive_tests
            ;;
        TEST-*|STRUCT-*)
            run_specific_test "$TEST_TYPE"
            ;;
        *)
            echo "Usage: $0 [all|structure|e2e|fixture|interactive|full|TEST-XX|STRUCT-XX]"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
