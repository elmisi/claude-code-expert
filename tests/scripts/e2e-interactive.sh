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

    local prompt="I want to create an automation in this project.

Topic: Block git push without explicit authorization

Here are my requirements (simulating interview answers):
- Timing: This must happen ALWAYS, on every git push attempt
- Guaranteed: Yes, it MUST be blocked, not just a suggestion
- Intelligence needed: No, a simple script check is enough
- Scope: This project only (not global)

Based on these requirements, create the appropriate automation.
Create the files in .claude/ directory.
Do NOT ask me questions - I've provided all the information above."

    log_info "Running Claude with hook creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 120 claude -p "$prompt" > /tmp/claude_output.txt 2>&1
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

    local prompt="I want to create an automation in this project.

Topic: API naming conventions for REST endpoints

Here are my requirements (simulating interview answers):
- Timing: Only when working on API-related code
- Guaranteed: No, it's a guideline Claude should follow
- Intelligence needed: Yes, Claude needs to understand context
- Scope: This project only
- Should be applied automatically when relevant (not manual invocation)

Based on these requirements, create the appropriate automation.
This should be a Skill with disable-model-invocation: false.
Create the files in .claude/skills/ directory.
Do NOT ask me questions - I've provided all the information above."

    log_info "Running Claude with skill creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 120 claude -p "$prompt" > /tmp/claude_output.txt 2>&1
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

    local prompt="I want to create an automation in this project.

Topic: Independent security code review

Here are my requirements (simulating interview answers):
- Timing: Only when explicitly requested
- Guaranteed: No
- Intelligence needed: Yes, deep analysis required
- Needs isolated context: Yes, should review without bias from previous context
- Scope: This project only

Based on these requirements, this should be a Subagent (not a skill).
Create a subagent file in .claude/agents/ directory.
Include: name, description, tools (Read, Grep, Glob, Bash), and model (sonnet).
Do NOT ask me questions - I've provided all the information above."

    log_info "Running Claude with subagent creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 120 claude -p "$prompt" > /tmp/claude_output.txt 2>&1
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

    local prompt="I want to create an automation in this project.

Topic: Allow git commit but block git push

Here are my requirements (simulating interview answers):
- This is a permission rule about what Claude can/cannot do
- I do NOT use --dangerously-skip-permissions
- Scope: This project only

Based on these requirements, create a Permissions configuration.
Add it to .claude/settings.json with allow and deny arrays.
Do NOT ask me questions - I've provided all the information above."

    log_info "Running Claude with permissions creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 120 claude -p "$prompt" > /tmp/claude_output.txt 2>&1
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

    local prompt="I want to create an automation in this project.

Topic: Always run tests before committing

Here are my requirements (simulating interview answers):
- Timing: Before every commit
- Guaranteed: No, just a reminder/guideline
- Intelligence needed: No, simple rule
- Scope: This project only

Based on these requirements, this should be a simple CLAUDE.md rule.
Create or update the CLAUDE.md file in the project root.
Do NOT ask me questions - I've provided all the information above."

    log_info "Running Claude with CLAUDE.md creation prompt..."

    cd "$TEST_SANDBOX"
    timeout 120 claude -p "$prompt" > /tmp/claude_output.txt 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out"
        return 1
    fi

    # Verify results
    log_info "Verifying created files..."

    if [ -f "$TEST_SANDBOX/CLAUDE.md" ]; then
        log_success "INTERACTIVE-CLAUDEMD-01: CLAUDE.md created"
        assert_file_contains "$TEST_SANDBOX/CLAUDE.md" -i "test" "INTERACTIVE-CLAUDEMD-02: Contains test reference"
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
