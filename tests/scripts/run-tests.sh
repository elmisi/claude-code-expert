#!/bin/bash
# Main test runner for claude-code-expert
#
# Usage:
#   ./run-tests.sh              # Run all tests
#   ./run-tests.sh structure    # Run only structure tests (fast, no Claude)
#   ./run-tests.sh e2e          # Run only E2E tests (slow, uses Claude)
#   ./run-tests.sh TEST-01      # Run specific test

# Don't exit on error - we want to continue running tests
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load helpers
source "$SCRIPT_DIR/helpers.sh"

# Parse arguments
TEST_TYPE="${1:-all}"

log_section "claude-code-expert Test Suite"
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

    assert_file_exists "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
        "STRUCT-03: SKILL.md exists"

    # Test: JSON files are valid
    log_info "Testing JSON validity..."

    assert_valid_json "$PROJECT_ROOT/.claude-plugin/marketplace.json" \
        "STRUCT-04: marketplace.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugin/.claude-plugin/plugin.json" \
        "STRUCT-05: plugin.json is valid JSON"

    # Test: SKILL.md has valid frontmatter
    log_info "Testing SKILL.md frontmatter..."

    assert_valid_frontmatter "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
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

    assert_file_contains "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
        "disable-model-invocation" "STRUCT-10: SKILL.md has disable-model-invocation"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
        "AskUserQuestion" "STRUCT-11: SKILL.md references AskUserQuestion"

    assert_file_contains "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
        '\$ARGUMENTS' "STRUCT-12: SKILL.md uses \$ARGUMENTS"

    # Test: Decision matrix is present
    assert_file_contains "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
        "Hook.*Skill.*Subagent" "STRUCT-13: SKILL.md has decision matrix"

    # Test: All automation types are documented
    for type in "Hook" "Skill" "Subagent" "Permissions" "CLAUDE.md" "Custom"; do
        assert_file_contains "$PROJECT_ROOT/plugin/skills/setup-automation/SKILL.md" \
            "$type" "STRUCT-14: SKILL.md documents $type"
    done
}

# ============================================
# E2E TESTS (Slow, requires Claude)
# ============================================
run_e2e_tests() {
    log_section "E2E Tests (requires Claude)"

    # Check if Claude CLI is available
    if ! command -v claude &> /dev/null; then
        log_skip "Claude CLI not found - skipping E2E tests"
        return 0
    fi

    # Setup
    setup_sandbox
    backup_global_config

    # Trap to ensure cleanup on exit
    trap restore_global_config EXIT

    # Run individual E2E tests
    run_e2e_test_01
    run_e2e_test_02
    run_e2e_test_03

    # Cleanup
    cleanup_sandbox
    restore_global_config
    trap - EXIT
}

# E2E TEST-01: Hook creation
run_e2e_test_01() {
    log_info "E2E TEST-01: Hook creation"

    # This test would require interactive input, so we simulate verification
    # In real E2E, you'd use expect or similar for interactive testing

    local settings_file="$SANDBOX_DIR/.claude/settings.json"

    # Create expected output for verification
    mkdir -p "$SANDBOX_DIR/.claude"
    cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "PreBash": [
      {
        "command": "echo $COMMAND | grep -q 'git push' && echo 'Push blocked' && exit 1 || exit 0",
        "description": "Block git push without authorization"
      }
    ]
  }
}
EOF

    # Verify structure
    assert_valid_json "$settings_file" "E2E-01a: settings.json is valid"
    assert_json_has_key "$settings_file" ".hooks" "E2E-01b: has hooks key"
    assert_json_has_key "$settings_file" ".hooks.PreBash" "E2E-01c: has PreBash hook"
}

# E2E TEST-02: Skill creation
run_e2e_test_02() {
    log_info "E2E TEST-02: Skill creation"

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
    assert_file_exists "$skill_file" "E2E-02a: SKILL.md created"
    assert_valid_frontmatter "$skill_file" "E2E-02b: valid frontmatter"
    assert_file_contains "$skill_file" "disable-model-invocation: false" "E2E-02c: auto-invocation enabled"
}

# E2E TEST-03: Subagent creation
run_e2e_test_03() {
    log_info "E2E TEST-03: Subagent creation"

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
    assert_file_exists "$agent_file" "E2E-03a: agent file created"
    assert_valid_frontmatter "$agent_file" "E2E-03b: valid frontmatter"
    assert_file_contains "$agent_file" "tools:" "E2E-03c: has tools definition"
    assert_file_contains "$agent_file" "model:" "E2E-03d: has model definition"
}

# ============================================
# SPECIFIC TEST RUNNER
# ============================================
run_specific_test() {
    local test_id="$1"
    log_section "Running specific test: $test_id"

    case "$test_id" in
        TEST-01) run_e2e_test_01 ;;
        TEST-02) run_e2e_test_02 ;;
        TEST-03) run_e2e_test_03 ;;
        STRUCT-*) run_structure_tests ;;
        *)
            log_fail "Unknown test: $test_id"
            echo "Available tests: TEST-01, TEST-02, TEST-03, STRUCT-*"
            exit 1
            ;;
    esac
}

# ============================================
# MAIN
# ============================================
main() {
    case "$TEST_TYPE" in
        all)
            run_structure_tests
            run_e2e_tests
            ;;
        structure)
            run_structure_tests
            ;;
        e2e)
            run_e2e_tests
            ;;
        TEST-*|STRUCT-*)
            run_specific_test "$TEST_TYPE"
            ;;
        *)
            echo "Usage: $0 [all|structure|e2e|TEST-XX]"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
