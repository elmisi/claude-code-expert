# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin (meta-plugin) that helps users decide and create the right automation type through an interactive interview. The user describes what they want to automate, the skill interviews them, applies a decision matrix, then creates and validates the correct files.

## Architecture

The plugin is built on a **schema / template / SKILL.md triangle**:

```
  SKILL.md (orchestrator)
    /            \
schemas/        templates/
(source of       (starting
 truth)           points)
```

- **Schemas** define what's valid. SKILL.md loads them at Step 0 and validates against them at Step 5.
- **Templates** are working baselines that SKILL.md customizes during creation.
- **SKILL.md** orchestrates everything: loads schemas, interviews user, applies decision matrix, creates files, validates.

When Claude Code changes (new hook events, new tools, etc.), update the **schema first**, then adjust templates and SKILL.md to match.

### SKILL.md Internals

The core is `plugin/skills/automate/SKILL.md` which implements:

1. **Command Router**: Parses `$ARGUMENTS` to dispatch sub-commands (`list`, `edit`, `delete`, `export`, `import`) or fall through to the creation workflow.
2. **8-Step Creation Workflow**: Load schemas → Interview → Decide → Explain → Create → Validate → Verify completeness → Test → Report.
3. **Two-Level Validation**: SKILL.md loads schemas at Step 0, validates against them at Step 5, and `plugin/scripts/validate-config.sh` provides external validation.
4. **Registry System**: All automations tracked in `~/.claude/automations-registry.json` with metadata (id, name, type, scope, path, timestamps). Enables list/edit/delete/export/import.

### Key Directories

- `plugin/schemas/` — Source of truth for valid configurations (hooks events, skill frontmatter, subagent tools/models, permission patterns, custom command limits, MCP servers, LSP servers, agent teams)
- `plugin/templates/` — Ready-to-use templates (hook variants, skill, subagent, permissions, custom command, MCP server, LSP server, agent team)
- `plugin/docs/claude-code-reference.md` — Reference copy; Step 0 fetches live docs from code.claude.com and diffs against this
- `tests/fixtures/` — Expected-output examples used by fixture tests
- `plugin/scripts/validate-config.sh` — External validation script (also used in CI)

## Version Files (IMPORTANT)

When bumping version, update ALL these files:
- `VERSION` — main version file
- `CHANGELOG.md` — add entry at top
- `plugin/.claude-plugin/plugin.json` — `"version"` field
- `.claude-plugin/marketplace.json` — `"version"` field in `plugins[]` array

The marketplace.json version is used by Claude Code's plugin update system. If out of sync, updates won't work.

## Running Tests

```bash
# Structure tests — fast, no Claude needed (39 tests, IDs: STRUCT-01..STRUCT-39)
./tests/scripts/run-tests.sh structure

# Fixture tests — validates expected output structures, no Claude needed (IDs: TEST-01..TEST-06)
./tests/scripts/run-tests.sh e2e

# Interactive tests — runs actual Claude, consumes tokens
./tests/scripts/run-tests.sh interactive

# Run a specific test by ID
./tests/scripts/run-tests.sh STRUCT-07
./tests/scripts/run-tests.sh TEST-01

# Full suite (structure + e2e + interactive)
./tests/scripts/run-tests.sh full
```

CI runs structure + e2e tests only (no API key needed). Interactive tests are local-only.

Test helpers are in `tests/scripts/helpers.sh` (assertions, sandbox management, `run_claude_headless()`).

### Validation Script

```bash
plugin/scripts/validate-config.sh <type> <content>
# <type>: hooks, skill, subagent, permissions, custom-commands, mcp-servers, lsp-servers, agent-team
# <content>: JSON/YAML string, file path, or '-' for stdin
# Exit codes: 0=valid, 1=invalid config, 2=usage error
```

## Schemas — Critical Constraints

Schemas in `plugin/schemas/` define what's valid. Key gotchas:

- **Hook events**: 12 valid events (`PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PermissionRequest`, `Notification`, `Stop`, `PreCompact`, `SubagentStart`, `SubagentStop`, `PostToolUseFailure`). NEVER use `PreCommit`, `PostCommit`, `PreBash`, `PostBash`, `BeforeToolUse`, `AfterToolUse` — they don't exist.
- **Hook exit codes**: `0` = allow, `2` = block (stderr becomes feedback), anything else = allow but log error. Exit code 1 does NOT block.
- **Hook structure**: Nested — `hooks.EventName[].hooks[]` (array inside array), not flat.
- **Hook handler types**: `command` (shell script), `prompt` (single-turn LLM), `agent` (multi-turn LLM). Fields: `async`, `timeout`, `statusMessage`, `model`.
- **Hook environment variables**: `CLAUDE_TOOL_INPUT` (JSON of tool inputs), `CLAUDE_PROJECT_DIR`, `CLAUDE_SESSION_ID`, `CLAUDE_ENV_FILE`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_CODE_REMOTE`.
- **Hook special outputs**: `PreToolUse` hooks can modify tool inputs via stdout JSON `{"hookSpecificOutput": {"updatedInput": {...}}}`. `PermissionRequest` hooks can control the decision via `{"hookSpecificOutput": {"decision": "allow"|"deny", "reason": "..."}}`.
- **Permissions**: Don't work with `--dangerously-skip-permissions`. Use hooks (exit 2) as a guaranteed alternative.
- **Skills**: `disable-model-invocation: true` = manual only (invoked via `/skill-name`); `false` = Claude auto-applies when relevant. Optional: `context: fork`, `hooks`.
- **Subagent tools**: `Read`, `Grep`, `Glob`, `Bash`, `Edit`, `Write`, `WebFetch`, `WebSearch`, `Task`, `NotebookEdit`, `AskUserQuestion`, `TaskOutput`, `ExitPlanMode`, `MCPSearch`. Plus MCP tools as `mcp__<server>__<tool>`.
- **Subagent models**: `opus`, `sonnet`, `haiku`, `inherit` (default: `inherit`).
- **Subagent memory field**: Optional `memory` array in frontmatter — values `user`, `project`, `local` control which memory files the subagent can read.
- **MCP servers**: Types: `stdio` (requires `command`) and `sse` (requires `url`). Tools named `mcp__<server>__<tool>`.
- **LSP servers**: Requires `command` and `languages` array.
- **Agent teams**: Experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Requires `name`, `description`, `agents` array.

## Automation Decision Matrix

| Need | Solution |
|------|----------|
| MUST happen every time | Hook |
| Claude needs to think | Skill |
| Isolated context needed | Subagent |
| Block specific actions | Permissions (or Hook if using --dangerously-skip-permissions) |
| Advisory rule | CLAUDE.md |
| Shortcut for a frequent prompt | Custom Command |
| External tool/service integration | MCP Server |
| Code intelligence | LSP Server |
| Parallel multi-agent orchestration | Agent Team (experimental) |

## Combination Rules

When the skill decides a combination is needed (e.g., "Hook + Skill"):
1. ALL components must be created — never partial implementations
2. ALL components must be validated against schemas and tested
3. ALL components must be registered in `~/.claude/automations-registry.json`
4. Related components must have `relatedHook`/`relatedSkill` links in the registry
5. Missing components must be fixed, not removed

## Registry Type Values

Valid values for the `type` field in automations-registry.json:
`skill`, `hook`, `subagent`, `permission`, `custom-command`, `claude-md`, `mcp-server`, `lsp-server`, `agent-team`

## File Markers

All auto-created files include origin markers:
- Markdown: `created-by: automate` in YAML frontmatter
- JSON: `_meta.createdBy` and `_meta.createdAt` fields

## Adding a New Automation Type

1. Create schema in `plugin/schemas/[type].json`
2. Create template in `plugin/templates/[type].json` (or `.md`)
3. Add `validate_[type]()` function in `validate-config.sh` and wire it into the `case` statement
4. Create fixture files in `tests/fixtures/`
5. Add structure + E2E test assertions in `run-tests.sh`
6. Update SKILL.md: decision matrix, Step 0 schema loading, Step 4 creation, combinations
7. Update `plugin/docs/claude-code-reference.md`

## Updating Schemas (When Claude Code Changes)

When Anthropic adds new hook events, tools, etc.: update the **schema** → update `validate-config.sh` → update SKILL.md inline lists → update `plugin/docs/claude-code-reference.md` → add structure tests if needed.
