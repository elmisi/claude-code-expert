# Tests for claude-code-expert

This directory contains tests for the claude-code-expert plugin.

## Structure

```
tests/
├── README.md              # This file
├── TEST.md                # Detailed test cases documentation (18 cases)
├── scripts/
│   ├── helpers.sh         # Test helper functions
│   ├── run-tests.sh       # Main test runner
│   └── e2e-interactive.sh # Interactive tests using Claude
├── fixtures/              # Expected output examples
│   ├── hook-only.json
│   ├── skill-auto.md
│   ├── skill-manual.md
│   ├── subagent.md
│   ├── permissions.json
│   ├── claude-md-rule.md
│   └── custom-command.json
└── sandbox/               # Temporary directory for test execution
```

## Running Tests

### Quick Test (Structure only - FREE, no Claude)
```bash
./tests/scripts/run-tests.sh structure
```
Validates JSON/YAML syntax, file structure, frontmatter. Fast, no tokens used.

### E2E Fixture Tests (FREE, no Claude)
```bash
./tests/scripts/run-tests.sh e2e
```
Creates expected files and validates their structure. Fast, no tokens used.

### All Free Tests
```bash
./tests/scripts/run-tests.sh all
```
Runs both structure and e2e fixture tests.

### Interactive Tests (USES TOKENS)
```bash
./tests/scripts/run-tests.sh interactive
```
Runs actual Claude commands to test file creation. Slow, consumes tokens.

Individual interactive tests:
```bash
./tests/scripts/e2e-interactive.sh hook       # Test hook creation
./tests/scripts/e2e-interactive.sh skill      # Test skill creation
./tests/scripts/e2e-interactive.sh subagent   # Test subagent creation
./tests/scripts/e2e-interactive.sh permissions # Test permissions
./tests/scripts/e2e-interactive.sh claudemd   # Test CLAUDE.md
```

### Full Test Suite (USES TOKENS)
```bash
./tests/scripts/run-tests.sh full
```
Runs everything: structure + e2e + interactive.

## Test Types

| Type | Claude | Tokens | Speed | What it tests |
|------|--------|--------|-------|---------------|
| `structure` | No | Free | Fast | File existence, JSON/YAML validity |
| `e2e` | No | Free | Fast | Expected output structure |
| `interactive` | Yes | ~$0.10-0.50 | Slow | Actual file creation by Claude |

## Test Coverage

### Structure Tests (19 tests)
- Plugin file structure
- JSON validity
- YAML frontmatter
- Required fields
- Documentation coverage

### E2E Fixture Tests (10 tests)
- Hook structure
- Skill structure
- Subagent structure

### Interactive Tests (5 scenarios)
- Hook creation from prompt
- Skill creation from prompt
- Subagent creation from prompt
- Permissions creation from prompt
- CLAUDE.md creation from prompt

## Fixtures

The `fixtures/` directory contains example expected outputs:

| File | Automation Type |
|------|-----------------|
| `hook-only.json` | Hook in settings.json |
| `skill-auto.md` | Skill with auto-invocation |
| `skill-manual.md` | Skill with manual invocation |
| `subagent.md` | Subagent definition |
| `permissions.json` | Permissions configuration |
| `claude-md-rule.md` | CLAUDE.md rule example |
| `custom-command.json` | Custom command definition |

## Adding New Tests

1. Document the test case in `TEST.md`
2. Add expected output to `fixtures/` if needed
3. For structure tests: add assertions in `run-tests.sh`
4. For interactive tests: add function in `e2e-interactive.sh`
5. Run and verify

## CI Integration

For CI pipelines, use only free tests:
```yaml
- name: Run tests
  run: ./tests/scripts/run-tests.sh all
```

For release validation (with Claude API key):
```yaml
- name: Run full tests
  run: ./tests/scripts/run-tests.sh full
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```
