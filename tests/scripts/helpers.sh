#!/bin/bash
# Test helper functions for claude-code-automation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Sandbox directory for isolated testing
SANDBOX_DIR="${SANDBOX_DIR:-$(pwd)/tests/sandbox}"
BACKUP_DIR="${BACKUP_DIR:-$(pwd)/tests/backup}"

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TESTS_SKIPPED++))
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Setup sandbox environment
setup_sandbox() {
    log_info "Setting up sandbox environment..."

    # Create sandbox directory
    mkdir -p "$SANDBOX_DIR"
    mkdir -p "$SANDBOX_DIR/.claude/skills"
    mkdir -p "$SANDBOX_DIR/.claude/agents"

    # Initialize as git repo (some tests need this)
    cd "$SANDBOX_DIR"
    git init -q 2>/dev/null || true

    log_info "Sandbox ready at: $SANDBOX_DIR"
}

# Cleanup sandbox
cleanup_sandbox() {
    log_info "Cleaning up sandbox..."
    rm -rf "$SANDBOX_DIR"
    mkdir -p "$SANDBOX_DIR"
}

# Backup current global config
backup_global_config() {
    log_info "Backing up global config..."
    mkdir -p "$BACKUP_DIR"

    if [ -f ~/.claude/settings.json ]; then
        cp ~/.claude/settings.json "$BACKUP_DIR/settings.json.bak"
    fi
    if [ -f ~/.claude/CLAUDE.md ]; then
        cp ~/.claude/CLAUDE.md "$BACKUP_DIR/CLAUDE.md.bak"
    fi
    if [ -d ~/.claude/skills ]; then
        cp -r ~/.claude/skills "$BACKUP_DIR/skills.bak"
    fi
    if [ -d ~/.claude/agents ]; then
        cp -r ~/.claude/agents "$BACKUP_DIR/agents.bak"
    fi
}

# Restore global config
restore_global_config() {
    log_info "Restoring global config..."

    if [ -f "$BACKUP_DIR/settings.json.bak" ]; then
        cp "$BACKUP_DIR/settings.json.bak" ~/.claude/settings.json
    fi
    if [ -f "$BACKUP_DIR/CLAUDE.md.bak" ]; then
        cp "$BACKUP_DIR/CLAUDE.md.bak" ~/.claude/CLAUDE.md
    fi
    if [ -d "$BACKUP_DIR/skills.bak" ]; then
        rm -rf ~/.claude/skills
        cp -r "$BACKUP_DIR/skills.bak" ~/.claude/skills
    fi
    if [ -d "$BACKUP_DIR/agents.bak" ]; then
        rm -rf ~/.claude/agents
        cp -r "$BACKUP_DIR/agents.bak" ~/.claude/agents
    fi

    rm -rf "$BACKUP_DIR"
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [ -f "$file" ]; then
        log_success "$test_name: File exists - $file"
        return 0
    else
        log_fail "$test_name: File missing - $file"
        return 1
    fi
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    local test_name="$2"

    if [ ! -f "$file" ]; then
        log_success "$test_name: File correctly absent - $file"
        return 0
    else
        log_fail "$test_name: File should not exist - $file"
        return 1
    fi
}

# Assert file contains string
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"

    if [ ! -f "$file" ]; then
        log_fail "$test_name: File not found - $file"
        return 1
    fi

    if grep -q "$pattern" "$file"; then
        log_success "$test_name: Pattern found in $file"
        return 0
    else
        log_fail "$test_name: Pattern not found in $file - looking for: $pattern"
        return 1
    fi
}

# Assert valid JSON
assert_valid_json() {
    local file="$1"
    local test_name="$2"

    if [ ! -f "$file" ]; then
        log_fail "$test_name: File not found - $file"
        return 1
    fi

    if jq empty "$file" 2>/dev/null; then
        log_success "$test_name: Valid JSON - $file"
        return 0
    else
        log_fail "$test_name: Invalid JSON - $file"
        return 1
    fi
}

# Assert valid YAML frontmatter in markdown
assert_valid_frontmatter() {
    local file="$1"
    local test_name="$2"

    if [ ! -f "$file" ]; then
        log_fail "$test_name: File not found - $file"
        return 1
    fi

    # Extract frontmatter between --- markers
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

    if [ -z "$frontmatter" ]; then
        log_fail "$test_name: No frontmatter found - $file"
        return 1
    fi

    # Check required fields
    if echo "$frontmatter" | grep -q "^name:"; then
        log_success "$test_name: Valid frontmatter - $file"
        return 0
    else
        log_fail "$test_name: Frontmatter missing 'name' field - $file"
        return 1
    fi
}

# Assert JSON has key
assert_json_has_key() {
    local file="$1"
    local key="$2"
    local test_name="$3"

    if [ ! -f "$file" ]; then
        log_fail "$test_name: File not found - $file"
        return 1
    fi

    if jq -e "$key" "$file" >/dev/null 2>&1; then
        log_success "$test_name: JSON has key $key"
        return 0
    else
        log_fail "$test_name: JSON missing key $key"
        return 1
    fi
}

# Run Claude headless with prompt
run_claude_headless() {
    local prompt="$1"
    local working_dir="${2:-$SANDBOX_DIR}"
    local timeout="${3:-120}"

    log_info "Running Claude headless: $prompt"

    cd "$working_dir"
    timeout "$timeout" claude -p "$prompt" --output-format json 2>&1
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_fail "Claude timed out after ${timeout}s"
        return 1
    fi

    return $exit_code
}

# Print test summary
print_summary() {
    echo ""
    log_section "Test Summary"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo ""

    if [ $TESTS_FAILED -gt 0 ]; then
        return 1
    fi
    return 0
}
