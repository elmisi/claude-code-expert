# Contributing to claude-code-automation

Thank you for your interest in contributing to **claude-code-automation** (`/automate`), a Claude Code plugin that helps users decide and create the right automation type through an interactive interview process.

## Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/elmisi/claude-code-automation.git
   cd claude-code-automation
   ```

2. Verify the project structure is intact:

   ```bash
   ./tests/scripts/run-tests.sh structure
   ```

   All structure tests should pass. These tests require only `jq` and `bash` -- no Claude CLI or API key needed.

3. (Optional) Run the full deterministic test suite:

   ```bash
   ./tests/scripts/run-tests.sh e2e
   ```

## Project Architecture

The plugin is built on a **schema / template / SKILL.md triangle**:

```
  SKILL.md (orchestrator)
    /            \
   /              \
schemas/        templates/
(source of       (starting
 truth)           points)
```

- **Schemas** (`plugin/schemas/*.json`) are the single source of truth. They define which hook events exist, which frontmatter fields are required, which tools a subagent can use, and so on. SKILL.md loads these schemas at Step 0 and validates against them at Step 5.

- **Templates** (`plugin/templates/`) are ready-to-use starting points for each automation type. They conform to the schemas and give users a working baseline that SKILL.md customizes during the creation workflow.

- **SKILL.md** (`plugin/skills/automate/SKILL.md`) is the orchestrator. It reads schemas to know what is valid, uses templates as a starting point, interviews the user, applies the decision matrix, creates the files, and validates them.

When Claude Code changes (new hook events, new tools, etc.), you update the **schema first**, then adjust templates and SKILL.md to match.

### Validation

There are two levels of validation:

1. **In-process**: SKILL.md loads schemas at Step 0 and checks generated configurations at Step 5.
2. **External**: `plugin/scripts/validate-config.sh` can validate any configuration from the command line, CI, or other scripts.

## How to Add a New Automation Type

Follow these steps in order:

### 1. Create the schema

Create `plugin/schemas/[type].json` defining all valid values, required fields, and constraints for the new automation type. Look at existing schemas (e.g., `hooks.json`, `skills.json`) for the expected format.

### 2. Create the template

Create `plugin/templates/[type].json` (or `.md` for Markdown-based types like skills and subagents). The template should be a minimal, working example that conforms to the schema.

### 3. Add validation

Add a `validate_[type]()` function in `plugin/scripts/validate-config.sh`. The function should:
- Parse the content (JSON with `jq`, or text with `grep`/`sed` for Markdown)
- Check all required fields
- Validate values against the schema's allowed set
- Return a non-zero exit code with descriptive error messages on failure

Add the new type to the `case` statement at the bottom of the script.

### 4. Create test fixtures

Create one or more fixture files in `tests/fixtures/` representing expected outputs. These serve as reference examples for E2E tests.

### 5. Add structure tests

Update `tests/scripts/run-tests.sh`:
- Add assertions in `run_structure_tests()` to verify the new schema, template, and any new SKILL.md sections exist
- Add E2E test functions that validate fixtures against the new type

### 6. Update SKILL.md

Update `plugin/skills/automate/SKILL.md` in these sections:
- **Decision matrix**: Add a row for the new type with the "when to use" guidance
- **Step 0 (Load schemas)**: Add the new schema to the list of schemas loaded at startup
- **Step 4 (Create)**: Add a creation section with the file paths, format, and schema-based validation rules
- **Common combinations**: If the new type can combine with existing types, document the combinations

### 7. Update reference docs

Update `plugin/docs/claude-code-reference.md` with documentation for the new automation type, including configuration format, valid values, and examples.

## How to Update Schemas (When Claude Code Adds New Features)

When Anthropic updates Claude Code with new features (new hook events, new tools, new configuration options):

### 1. Check official documentation

Visit [code.claude.com](https://code.claude.com) and review the latest documentation for the changed feature area.

### 2. Update the relevant schema

Edit the appropriate file in `plugin/schemas/` to add new valid values, fields, or constraints. For example, if a new hook event is added, update `hooks.json` and the `VALID_HOOK_EVENTS` array in `validate-config.sh`.

### 3. Update SKILL.md references

Update `plugin/skills/automate/SKILL.md` so it knows about the new valid values. This includes any inline lists of valid events, tools, models, etc.

### 4. Update reference docs

Update `plugin/docs/claude-code-reference.md` to reflect the changes.

### 5. Add structure tests if needed

If the schema change introduces new required files or sections, add corresponding assertions in `tests/scripts/run-tests.sh`.

## Testing

The test suite has three tiers:

| Type | Command | Speed | Requires Claude? | What it tests |
|------|---------|-------|-------------------|---------------|
| **Structure** | `./tests/scripts/run-tests.sh structure` | Fast (seconds) | No | File existence, JSON validity, frontmatter format, required fields and sections in SKILL.md |
| **E2E** | `./tests/scripts/run-tests.sh e2e` | Fast (seconds) | No | Fixture-based tests that create expected outputs in a sandbox and validate their structure and content |
| **Interactive** | `./tests/scripts/run-tests.sh interactive` | Slow (minutes) | Yes (consumes tokens) | Qualitative smoke tests that run actual Claude commands to verify the end-to-end interview and creation workflow |

Run a specific test by ID:

```bash
./tests/scripts/run-tests.sh STRUCT-07
./tests/scripts/run-tests.sh TEST-01
```

Run the full suite (all three tiers):

```bash
./tests/scripts/run-tests.sh full
```

**Note**: CI runs only structure and E2E tests. Interactive tests are for local development and require a Claude API key.

## Pull Request Checklist

Before submitting a PR, verify the following:

- [ ] Schemas are updated (if changing valid values or adding a new type)
- [ ] Schema changes are reflected in `plugin/skills/automate/SKILL.md`
- [ ] Schema changes are reflected in `plugin/docs/claude-code-reference.md`
- [ ] `validate-config.sh` is updated (if adding a new type or changing validation rules)
- [ ] Structure tests pass: `./tests/scripts/run-tests.sh structure`
- [ ] E2E fixture tests pass: `./tests/scripts/run-tests.sh e2e`
- [ ] New fixtures validate against their schema via `validate-config.sh`
- [ ] `CHANGELOG.md` is updated with a description of the change
- [ ] Version is bumped in all 4 version files (if this is a release):
  - `VERSION`
  - `CHANGELOG.md`
  - `plugin/.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`

## Code of Conduct

Be respectful, constructive, and collaborative. We are all here to make Claude Code automations easier for everyone.
