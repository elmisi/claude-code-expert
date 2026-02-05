# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that helps users decide and create the right automation type (skills, hooks, subagents, permissions, CLAUDE.md, custom commands) through an interactive interview process.

## Project Structure

```
.
├── plugin/                     # The actual plugin distributed to users
│   ├── .claude-plugin/         # Plugin metadata (plugin.json with version)
│   ├── skills/setup-automation/ # Main skill (SKILL.md)
│   ├── schemas/                # JSON schemas defining valid configurations
│   ├── templates/              # Ready-to-use templates for each automation type
│   ├── scripts/                # Validation scripts
│   └── docs/                   # Reference documentation
├── .claude-plugin/             # Marketplace metadata (marketplace.json)
├── tests/                      # Test cases and scripts
├── VERSION                     # Current version (semver)
└── CHANGELOG.md                # Version history
```

## Version Files (IMPORTANT)

When bumping version, update ALL these files:
- `VERSION` - main version file
- `CHANGELOG.md` - add entry at top
- `plugin/.claude-plugin/plugin.json` - `"version"` field
- `.claude-plugin/marketplace.json` - `"version"` field in `plugins[]` array

The marketplace.json version is used by Claude Code's plugin update system. If out of sync, updates won't work.

## Running Tests

```bash
# Structure tests (no Claude needed)
./tests/scripts/run-tests.sh structure

# Interactive E2E tests (requires Claude, consumes tokens)
./tests/scripts/run-tests.sh interactive

# Full test suite
./tests/scripts/run-tests.sh full
```

## Key Schemas

The `plugin/schemas/` directory contains the source of truth for valid configurations:

- **hooks.json**: Valid events are `PreToolUse`, `PostToolUse`, `SessionStart`, etc. NEVER use `PreCommit`, `PostCommit`, `PreBash` - they don't exist.
- **skills.json**: Required frontmatter fields
- **subagents.json**: Valid tools and models

## Automation Decision Matrix

| Need | Solution |
|------|----------|
| MUST happen every time | Hook |
| Claude needs to think | Skill |
| Isolated context needed | Subagent |
| Block specific actions | Permissions (or Hook if using --dangerously-skip-permissions) |
| Advisory rule | CLAUDE.md |

## Combination Rules

When the skill decides a combination is needed (e.g., "Hook + Skill"):
1. ALL components must be created
2. ALL components must be tested
3. ALL components must be registered in `~/.claude/automations-registry.json`
4. Related components must have `relatedHook`/`relatedSkill` links

Never create partial implementations.
