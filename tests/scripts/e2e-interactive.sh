#!/bin/bash
# Interactive E2E tests using Claude headless mode
# These tests run actual Claude commands with pre-defined prompts
# that include simulated user answers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

# Test sandbox - isolated directory for each test
TEST_SANDBOX="$PROJECT_ROOT/tests/sandbox/interactive"

# Cleanup and setup
setup_interactive_sandbox() {
    log_info "Setting up interactive test sandbox..."
    rm -rf "$TEST_SANDBOX"
    mkdir -p "$TEST_SANDBOX/.claude/skills"
    mkdir -p "$TEST_SANDBOX/.claude/agents"
    cd "$TEST_SANDBOX"
    git init -q
    echo "# Test Project" > README.md
    git add . && git commit -q -m "init"
}

cleanup_interactive_sandbox() {
    log_info "Cleaning up interactive sandbox..."
    rm -rf "$TEST_SANDBOX"
}

# ============================================
# INTERACTIVE E2E TEST: Hook Creation
# ============================================
test_interactive_hook() {
    log_section "Interactive E2E: Hook Creation"

    setup_interactive_sandbox

    local prompt="Create a Claude Code hook configuration to block git push.

I need a .claude/settings.json file with a hooks section that blocks any bash command containing 'git push'.

The format should be:
{
  \"hooks\": {
    \"PreBash\": [
      {
        \"command\": \"<script that checks and blocks git push>\",
        \"description\": \"Block git push\"
      }
    ]
  }
}

Create ONLY the .claude/settings.json file. Do not create git hooks or any other files."

    log_info "Running Claude with hook creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 180 claude -p "$prompt" --dangerously-skip-permissions > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    if [ -f "$TEST_SANDBOX/.claude/settings.json" ]; then
        assert_valid_json "$TEST_SANDBOX/.claude/settings.json" "INTERACTIVE-HOOK-01: settings.json valid"

        if jq -e '.hooks' "$TEST_SANDBOX/.claude/settings.json" > /dev/null 2>&1; then
            log_success "INTERACTIVE-HOOK-02: Hook created in settings.json"
        else
            log_fail "INTERACTIVE-HOOK-02: No hooks in settings.json"
        fi
    else
        log_fail "INTERACTIVE-HOOK-01: settings.json not created"
    fi

    cleanup_interactive_sandbox
}

# ============================================
# INTERACTIVE E2E TEST: Skill Creation
# ============================================
test_interactive_skill() {
    log_section "Interactive E2E: Skill Creation"

    setup_interactive_sandbox

    local prompt="Create a Claude Code skill for API naming conventions.

Create a file at .claude/skills/api-conventions/SKILL.md with this structure:

---
name: api-conventions
description: REST API naming conventions
disable-model-invocation: false
---

# API Conventions

Rules:
- Use kebab-case for URL paths
- Use camelCase for JSON properties
- Include pagination for list endpoints

Create ONLY the .claude/skills/api-conventions/SKILL.md file."

    log_info "Running Claude with skill creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 180 claude -p "$prompt" --dangerously-skip-permissions > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    local skill_found=false
    for skill_dir in "$TEST_SANDBOX/.claude/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            local skill_file="$skill_dir/SKILL.md"
            if [ -f "$skill_file" ]; then
                skill_found=true
                assert_valid_frontmatter "$skill_file" "INTERACTIVE-SKILL-01: SKILL.md has valid frontmatter"
                assert_file_contains "$skill_file" "disable-model-invocation" "INTERACTIVE-SKILL-02: Has invocation setting"
                break
            fi
        fi
    done

    if [ "$skill_found" = false ]; then
        log_fail "INTERACTIVE-SKILL-01: No skill file created"
    fi

    cleanup_interactive_sandbox
}

# ============================================
# INTERACTIVE E2E TEST: Subagent Creation
# ============================================
test_interactive_subagent() {
    log_section "Interactive E2E: Subagent Creation"

    setup_interactive_sandbox

    local prompt="Create a Claude Code subagent for security review.

Create a file at .claude/agents/security-reviewer.md with this structure:

---
name: security-reviewer
description: Security code review
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a security reviewer. Check for:
- Injection vulnerabilities
- Authentication issues
- Data exposure

Create ONLY the .claude/agents/security-reviewer.md file."

    log_info "Running Claude with subagent creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 180 claude -p "$prompt" --dangerously-skip-permissions > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    local agent_found=false
    for agent_file in "$TEST_SANDBOX/.claude/agents"/*.md; do
        if [ -f "$agent_file" ]; then
            agent_found=true
            assert_valid_frontmatter "$agent_file" "INTERACTIVE-AGENT-01: Agent has valid frontmatter"
            assert_file_contains "$agent_file" "tools:" "INTERACTIVE-AGENT-02: Has tools definition"
            assert_file_contains "$agent_file" "model:" "INTERACTIVE-AGENT-03: Has model definition"
            break
        fi
    done

    if [ "$agent_found" = false ]; then
        log_fail "INTERACTIVE-AGENT-01: No agent file created"
    fi

    cleanup_interactive_sandbox
}

# ============================================
# INTERACTIVE E2E TEST: Permissions
# ============================================
test_interactive_permissions() {
    log_section "Interactive E2E: Permissions Creation"

    setup_interactive_sandbox

    local prompt="Create a Claude Code permissions configuration.

Create a file at .claude/settings.json with this structure:

{
  \"permissions\": {
    \"allow\": [\"Bash(git commit *)\", \"Bash(git add *)\"],
    \"deny\": [\"Bash(git push *)\"]
  }
}

Create ONLY the .claude/settings.json file with permissions config."

    log_info "Running Claude with permissions creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 180 claude -p "$prompt" --dangerously-skip-permissions > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    if [ -f "$TEST_SANDBOX/.claude/settings.json" ]; then
        assert_valid_json "$TEST_SANDBOX/.claude/settings.json" "INTERACTIVE-PERM-01: settings.json valid"

        if jq -e '.permissions' "$TEST_SANDBOX/.claude/settings.json" > /dev/null 2>&1; then
            log_success "INTERACTIVE-PERM-02: Permissions created"

            if jq -e '.permissions.allow' "$TEST_SANDBOX/.claude/settings.json" > /dev/null 2>&1; then
                log_success "INTERACTIVE-PERM-03: Has allow list"
            else
                log_fail "INTERACTIVE-PERM-03: Missing allow list"
            fi

            if jq -e '.permissions.deny' "$TEST_SANDBOX/.claude/settings.json" > /dev/null 2>&1; then
                log_success "INTERACTIVE-PERM-04: Has deny list"
            else
                log_fail "INTERACTIVE-PERM-04: Missing deny list"
            fi
        else
            log_fail "INTERACTIVE-PERM-02: No permissions in settings.json"
        fi
    else
        log_fail "INTERACTIVE-PERM-01: settings.json not created"
    fi

    cleanup_interactive_sandbox
}

# ============================================
# INTERACTIVE E2E TEST: CLAUDE.md Rule
# ============================================
test_interactive_claude_md() {
    log_section "Interactive E2E: CLAUDE.md Rule"

    setup_interactive_sandbox

    local prompt="Create a CLAUDE.md file in the project root.

Create a file at CLAUDE.md (in current directory, not in .claude/) with:

# Project Rules

## Testing
Before committing, always run tests with: npm test

Ensure all tests pass before creating a commit.

Create ONLY the CLAUDE.md file in the project root."

    log_info "Running Claude with CLAUDE.md creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 180 claude -p "$prompt" --dangerously-skip-permissions > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    if [ -f "$TEST_SANDBOX/CLAUDE.md" ]; then
        log_success "INTERACTIVE-CLAUDEMD-01: CLAUDE.md created"
        assert_file_contains "$TEST_SANDBOX/CLAUDE.md" "test" "INTERACTIVE-CLAUDEMD-02: Contains test reference"
    else
        log_fail "INTERACTIVE-CLAUDEMD-01: CLAUDE.md not created"
    fi

    cleanup_interactive_sandbox
}

# ============================================
# MAIN
# ============================================
main() {
    log_section "Interactive E2E Tests"
    log_info "These tests run actual Claude commands"
    log_info "They may take a few minutes and consume tokens"
    echo ""

    # Check if Claude is available
    if ! command -v claude &> /dev/null; then
        log_fail "Claude CLI not found - cannot run interactive tests"
        exit 1
    fi

    # Run tests
    test_interactive_hook
    test_interactive_skill
    test_interactive_subagent
    test_interactive_permissions
    test_interactive_claude_md

    # Summary
    print_summary
}

# Allow running individual tests
case "${1:-all}" in
    hook) test_interactive_hook ;;
    skill) test_interactive_skill ;;
    subagent) test_interactive_subagent ;;
    permissions) test_interactive_permissions ;;
    claudemd) test_interactive_claude_md ;;
    all) main ;;
    *)
        echo "Usage: $0 [all|hook|skill|subagent|permissions|claudemd]"
        exit 1
        ;;
esac
