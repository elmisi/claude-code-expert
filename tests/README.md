# Tests for claude-code-expert

This directory contains tests for the claude-code-expert plugin.

## Structure

```
tests/
├── README.md           # This file
├── TEST.md             # Detailed test cases documentation
├── scripts/
│   ├── helpers.sh      # Test helper functions
│   └── run-tests.sh    # Main test runner
├── fixtures/           # Expected output examples
│   ├── hook-only.json
│   ├── skill-auto.md
│   ├── skill-manual.md
│   ├── subagent.md
│   ├── permissions.json
│   ├── claude-md-rule.md
│   └── custom-command.json
└── sandbox/            # Temporary directory for test execution
```

## Running Tests

### Quick Test (Structure only, no Claude needed)
```bash
./tests/scripts/run-tests.sh structure
```

### Full Test Suite
```bash
./tests/scripts/run-tests.sh all
```

### E2E Tests Only (requires Claude)
```bash
./tests/scripts/run-tests.sh e2e
```

### Specific Test
```bash
./tests/scripts/run-tests.sh TEST-01
```

## Test Types

### Structure Tests (Fast)
- Validate JSON/YAML syntax
- Check required files exist
- Verify frontmatter format
- No Claude CLI needed

### E2E Tests (Slow)
- Run actual plugin scenarios
- Verify file creation
- Check output structure
- Requires Claude CLI

## Fixtures

The `fixtures/` directory contains example expected outputs:

| File | Description |
|------|-------------|
| `hook-only.json` | Expected hook structure |
| `skill-auto.md` | Skill with auto-invocation |
| `skill-manual.md` | Skill with manual invocation |
| `subagent.md` | Subagent definition |
| `permissions.json` | Permissions configuration |
| `claude-md-rule.md` | CLAUDE.md rule example |
| `custom-command.json` | Custom command definition |

## Adding New Tests

1. Document the test case in `TEST.md`
2. Add expected output to `fixtures/` if needed
3. Add test function to `run-tests.sh`
4. Run and verify
