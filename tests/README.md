# Tests for claude-code-automation

This directory contains tests for the claude-code-automation plugin.

## Structure

```
tests/
├── README.md              # This file
├── TEST.md                # Detailed test cases documentation (21 scenarios)
├── scripts/
│   ├── helpers.sh         # Test helper functions (assertions, sandbox, validation)
│   ├── run-tests.sh       # Main test runner
│   └── e2e-interactive.sh # Interactive tests using actual Claude (costs tokens)
├── fixtures/              # Expected output examples for validation
│   ├── hook-only.json
│   ├── skill-auto.md
│   ├── skill-manual.md
│   ├── subagent.md
│   ├── permissions.json
│   ├── claude-md-rule.md
│   ├── custom-command.json
│   ├── mcp-server.json
│   ├── lsp-server.json
│   └── agent-team.json
└── sandbox/               # Temporary directory for test execution (gitignored)
```

## Running Tests

### Structure Tests (FREE, no Claude)
```bash
./tests/scripts/run-tests.sh structure
```
Validates file structure, JSON/YAML syntax, frontmatter, schema presence, fixture validation against `validate-config.sh`, version sync across all 4 version files, and negative validation (rejects invalid configs). **39 tests.**

### Fixture Tests (FREE, no Claude)
```bash
./tests/scripts/run-tests.sh e2e       # or: ./run-tests.sh fixture
```
Creates expected output files in a sandbox and validates their structure (JSON keys, frontmatter fields). **20 tests.**

### All Free Tests
```bash
./tests/scripts/run-tests.sh all
```
Runs both structure and fixture tests.

### Interactive Tests (USES TOKENS)
```bash
./tests/scripts/run-tests.sh interactive
```
Runs actual Claude commands to test the skill end-to-end. These are **qualitative smoke tests** — they verify the skill produces reasonable output, but results depend on the model's behavior and are not deterministic. Covers 5 scenarios: hook, skill, subagent, permissions, CLAUDE.md. Does not yet cover MCP Server, LSP Server, or Agent Team creation.

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
Runs everything: structure + fixture + interactive.

## Test Types

| Type | Claude | Tokens | Speed | CI | What it tests |
|------|--------|--------|-------|-----|---------------|
| `structure` | No | Free | Fast | Yes | File existence, JSON validity, fixture validation, version sync, negative validation |
| `fixture` | No | Free | Fast | Yes | Expected output structure in sandbox |
| `interactive` | Yes | ~$0.10-0.50 | Slow | No | Actual file creation by Claude (qualitative) |

## Test Coverage

### Structure Tests (39 tests)
- Plugin file structure (STRUCT-01 to STRUCT-03)
- JSON validity (STRUCT-04 to STRUCT-05)
- YAML frontmatter (STRUCT-06)
- Required fields (STRUCT-07 to STRUCT-09)
- SKILL.md content (STRUCT-10 to STRUCT-14)
- New schema files (STRUCT-15 to STRUCT-20)
- SKILL.md documents new types (STRUCT-21 to STRUCT-23)
- Fixture validation against validate-config.sh (STRUCT-24 to STRUCT-32)
- Version sync (STRUCT-33)
- Negative validation — invalid configs rejected (STRUCT-34 to STRUCT-39)

### Fixture Tests (20 tests)
- Hook structure (FIX-01a to FIX-01c)
- Skill structure (FIX-02a to FIX-02c)
- Subagent structure (FIX-03a to FIX-03d)
- MCP server structure (FIX-04a to FIX-04c)
- LSP server structure (FIX-05a to FIX-05c)
- Agent team structure (FIX-06a to FIX-06d)

### Interactive Tests (5 scenarios)
- Hook creation from prompt
- Skill creation from prompt
- Subagent creation from prompt
- Permissions creation from prompt
- CLAUDE.md creation from prompt

## Fixtures

The `fixtures/` directory contains example expected outputs:

| File | Automation Type | Validated By |
|------|-----------------|--------------|
| `hook-only.json` | Hook in settings.json | `validate-config.sh hooks` |
| `skill-auto.md` | Skill with auto-invocation | `validate-config.sh skill` |
| `skill-manual.md` | Skill with manual invocation | `validate-config.sh skill` |
| `subagent.md` | Subagent definition | `validate-config.sh subagent` |
| `permissions.json` | Permissions configuration | `validate-config.sh permissions` |
| `claude-md-rule.md` | CLAUDE.md rule example | (no validator) |
| `custom-command.json` | Custom command definition | `validate-config.sh custom-commands` |
| `mcp-server.json` | MCP server configuration | `validate-config.sh mcp-servers` |
| `lsp-server.json` | LSP server configuration | `validate-config.sh lsp-servers` |
| `agent-team.json` | Agent team configuration | `validate-config.sh agent-team` |

## Adding New Tests

1. Document the test case in `TEST.md`
2. Add expected output to `fixtures/` if needed
3. For structure tests: add assertions in `run-tests.sh` under `run_structure_tests()`
4. For fixture tests: add a `run_fixture_test_XX()` function in `run-tests.sh`
5. For interactive tests: add function in `e2e-interactive.sh`
6. Run and verify

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
