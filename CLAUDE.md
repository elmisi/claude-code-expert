# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin (meta-plugin) that helps users decide and create the right automation type through an interactive interview. The user describes what they want to automate, the skill interviews them, applies a decision matrix, then creates and validates the correct files.

## Architecture

The core is `plugin/skills/automate/SKILL.md` — a skill file that implements:

1. **Command Router**: Parses `$ARGUMENTS` to dispatch sub-commands (`list`, `edit`, `delete`, `export`, `import`) or fall through to the creation workflow.
2. **8-Step Creation Workflow**: Load schemas → Interview → Decide → Explain → Create → Validate → Verify completeness → Test → Report.
3. **Two-Level Validation**: SKILL.md loads schemas at Step 0, validates against them at Step 5, and `plugin/scripts/validate-config.sh` provides external validation.
4. **Registry System**: All automations tracked in `~/.claude/automations-registry.json` with metadata (id, name, type, scope, path, timestamps). Enables list/edit/delete/export/import.

### Key Directories

- `plugin/schemas/` — Source of truth for valid configurations (hooks events, skill frontmatter, subagent tools/models, permission patterns, custom command limits, MCP servers, LSP servers, agent teams)
- `plugin/templates/` — Ready-to-use templates (hook variants, skill, subagent, permissions, custom command, MCP server, LSP server, agent team)
- `plugin/docs/claude-code-reference.md` — Reference copy; Step 0 fetches live docs from code.claude.com and diffs against this
- `tests/fixtures/` — Expected-output examples used by E2E tests (hooks, skills, subagent, permissions, custom command, MCP server, LSP server, agent team)

## Version Files (IMPORTANT)

When bumping version, update ALL these files:
- `VERSION` — main version file
- `CHANGELOG.md` — add entry at top
- `plugin/.claude-plugin/plugin.json` — `"version"` field
- `.claude-plugin/marketplace.json` — `"version"` field in `plugins[]` array

The marketplace.json version is used by Claude Code's plugin update system. If out of sync, updates won't work.

## Running Tests

```bash
# Structure tests — fast, no Claude needed (23 tests)
./tests/scripts/run-tests.sh structure

# E2E fixture tests — validates against fixtures, no Claude needed
./tests/scripts/run-tests.sh e2e

# Interactive tests — runs actual Claude, consumes tokens
./tests/scripts/run-tests.sh interactive

# Run a specific test by ID
./tests/scripts/run-tests.sh STRUCT-07

# Full suite (structure + e2e + interactive)
./tests/scripts/run-tests.sh full
```

Test helpers are in `tests/scripts/helpers.sh` (assertions, sandbox management, `run_claude_headless()`). Validation script: `plugin/scripts/validate-config.sh <type> <content>` (types: hooks, skill, subagent, permissions, custom-commands, mcp-servers, lsp-servers, agent-team).

## Schemas — Critical Constraints

Schemas in `plugin/schemas/` define what's valid. Key gotchas:

- **Hook events**: 12 valid events (`PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PermissionRequest`, `Notification`, `Stop`, `PreCompact`, `SubagentStart`, `SubagentStop`, `PostToolUseFailure`). NEVER use `PreCommit`, `PostCommit`, `PreBash`, `PostBash`, `BeforeToolUse`, `AfterToolUse` — they don't exist.
- **Hook exit codes**: `0` = allow, `2` = block (stderr becomes feedback), anything else = allow but log error. Exit code 1 does NOT block.
- **Hook structure**: Nested — `hooks.EventName[].hooks[]` (array inside array), not flat.
- **Hook handler types**: `command` (shell script), `prompt` (single-turn LLM), `agent` (multi-turn LLM). Fields: `async`, `timeout`, `statusMessage`, `model`.
- **Permissions**: Don't work with `--dangerously-skip-permissions`. Use hooks (exit 2) as a guaranteed alternative.
- **Skills**: `disable-model-invocation: true` = manual only (invoked via `/skill-name`); `false` = Claude auto-applies when relevant. Optional: `context: fork`, `hooks`.
- **Subagent tools**: `Read`, `Grep`, `Glob`, `Bash`, `Edit`, `Write`, `WebFetch`, `WebSearch`, `Task`, `NotebookEdit`, `AskUserQuestion`, `TaskOutput`, `ExitPlanMode`, `MCPSearch`. Plus MCP tools as `mcp__<server>__<tool>`.
- **Subagent models**: `opus`, `sonnet`, `haiku`, `inherit` (default: `inherit`).
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
