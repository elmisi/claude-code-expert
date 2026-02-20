# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-02-20

### Changed
- Expanded CLAUDE.md with hook environment variables, hook special outputs (`updatedInput`, `decision`), and subagent `memory` field documentation

## [2.0.0] - 2026-02-06

### Breaking Changes
- Renamed project from `claude-code-expert` to `claude-code-automation`
- Renamed skill command from `/setup-automation` to `/automate`
- Updated all references, file markers, and GitHub URLs

### Added
- **MCP Servers**: Full support for Model Context Protocol server configuration (schema, template, fixture, validation)
- **LSP Servers**: Full support for Language Server Protocol configuration (schema, template, fixture, validation)
- **Agent Teams**: Full support for experimental multi-agent orchestration (schema, template, fixture, validation)
- New schemas: `mcp-servers.json`, `lsp-servers.json`, `agent-teams.json`
- New templates: `mcp-server.json`, `lsp-server.json`, `agent-team.json`
- New test fixtures: `mcp-server.json`, `lsp-server.json`, `agent-team.json`
- Hook handler fields: `async`, `timeout`, `statusMessage`, `model` for prompt/agent hooks
- Hook capabilities: `updatedInput` (PreToolUse input modification), `permissionDecision` (PermissionRequest control)
- Subagent fields: `disallowedTools`, `permissionMode`, `skills`, `hooks`, `memory`
- Subagent model default changed to `inherit`; new tools: `AskUserQuestion`, `TaskOutput`, `ExitPlanMode`, `MCPSearch`
- Skill fields: `context` (fork mode), `hooks` (scoped hooks)
- Built-in agents documentation (Explore, Plan, general-purpose, Bash)
- New environment variables: `CLAUDE_ENV_FILE`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_CODE_REMOTE`
- Decision matrix expanded with MCP Server, LSP Server, Agent Team columns
- New combination patterns: MCP Server + Skill, Agent Team + Skill
- Registry type values: `mcp-server`, `lsp-server`, `agent-team`
- CONTRIBUTING.md with development setup, architecture overview, and PR checklist
- GitHub issue templates (bug report, feature request, schema update)
- Pull request template
- GitHub Actions CI workflow (structure tests, E2E tests, fixture validation)
- CI badge in README
- Testing section in README explaining qualitative vs deterministic tests

### Changed
- Updated all schemas to match Claude Code 2026 features
- Reference documentation expanded with MCP, LSP, Agent Teams sections
- SKILL.md interview includes questions about external tools, code intelligence, and parallel agents
- Validation script (`validate-config.sh`) supports new types: `mcp-servers`, `lsp-servers`, `agent-team`
- Structure tests expanded from 14 to 23 (STRUCT-15 through STRUCT-23 for new types)
- E2E tests expanded with TEST-04 (MCP), TEST-05 (LSP), TEST-06 (Agent Team)

### Fixed
- TEST-01 fixture: `PreBash` (invalid) → `PreToolUse` with `Bash` matcher (valid)
- TEST-09 description: `PreWrite` (invalid) → `PreToolUse` with `Edit|Write` matcher (valid)

## [1.5.1] - 2026-02-05

### Added
- CLAUDE.md with project guidance for Claude Code instances

## [1.5.0] - 2026-02-05

### Added
- Mandatory completion verification for combination automations (Hook + Skill, etc.)
- Step 6: Verify COMPLETENESS - ensures all planned components are created
- Step 7: Test the automation - mandatory testing before finishing
- Step 8: Final report - checklist of all completed components
- CRITICAL RULE section emphasizing "complete all or nothing"

### Changed
- Common combinations section now lists REQUIRED components explicitly
- Important notes split into NEVER/ALWAYS rules for clarity
- Combinations must have relatedHook/relatedSkill links in registry

### Fixed
- Prevent incomplete automations (e.g., promising "Hook + Skill" but only creating skill)
- Prevent removing broken components instead of fixing them

## [1.4.1] - 2026-02-05

### Added
- Documentation for automation management sub-commands in README

## [1.4.0] - 2026-02-05

### Added
- Automation registry system (`~/.claude/automations-registry.json`)
- Sub-commands for setup-automation skill: `list`, `edit`, `delete`, `export`, `import`
- File markers (`created-by: setup-automation`) for tracking automation origin
- Export/import functionality for sharing automations between machines

### Changed
- setup-automation skill now includes Command Router for sub-command parsing
- All new automations are automatically tracked in the registry

## [1.3.0] - 2025-02-04

### Added
- Validation schemas in `plugin/schemas/` for hooks, skills, subagents, permissions, custom-commands
- Ready-to-use templates in `plugin/templates/` for all automation types
- Validation script `plugin/scripts/validate-config.sh` to check configurations before creation
- Semi-automatic documentation update workflow with diff preview

### Changed
- SKILL.md now reads schemas to validate configurations before creating files
- Documentation explicitly lists invalid hook events to avoid common mistakes
- Improved error prevention with explicit lists of valid values

### Fixed
- Test fixture `hook-only.json` corrected from invalid `PreBash` to valid `PreToolUse`

## [1.2.2] - 2025-02-04

### Fixed
- Corrected hook event names (PreToolUse, PostToolUse, etc. instead of invalid PreCommit)
- Fixed hook JSON structure (nested `hooks` array with `matcher` and `type`)
- Updated documentation with valid hook events and correct format

## [1.2.1] - 2025-02-04

### Fixed
- Interactive E2E tests now use `--dangerously-skip-permissions` for file creation
- Improved test prompts for more reliable file generation
- Fixed assert_file_contains bug in CLAUDE.md test

## [1.2.0] - 2025-02-04

### Added
- Interactive E2E tests that run actual Claude commands
- `tests/scripts/e2e-interactive.sh` for testing real file creation
- 5 interactive test scenarios (hook, skill, subagent, permissions, CLAUDE.md)
- `./run-tests.sh interactive` command for token-based tests
- `./run-tests.sh full` command for complete test suite

## [1.1.0] - 2025-02-04

### Added
- Test framework with 18 documented test cases
- Structure tests (fast, no Claude needed)
- E2E test scaffolding (requires Claude)
- Test fixtures for all automation types
- `tests/TEST.md` with detailed test documentation
- `tests/scripts/run-tests.sh` main test runner
- `tests/scripts/helpers.sh` test utilities

## [1.0.3] - 2025-02-04

### Changed
- Translated SKILL.md from Italian to English

## [1.0.2] - 2025-02-04

### Changed
- Populated CHANGELOG with proper format and history

## [1.0.1] - 2025-02-04

### Added
- CHANGELOG.md file
- VERSION file for tracking releases

## [1.0.0] - 2025-02-04

### Added
- Initial release
- `setup-automation` skill for deciding and creating Claude Code automations
- Decision matrix for choosing between hooks, skills, subagents, permissions, CLAUDE.md, and custom commands
- Auto-update feature to fetch latest Claude Code documentation
- Interactive interview workflow using AskUserQuestion
- Support for marketplace installation
