# claude-code-automation

> An expert advisor plugin for Claude Code that helps you decide and create the right automation for your needs.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml/badge.svg)](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml)

**Schemas updated: Feb 2026** — Covers all Claude Code automation types including MCP Servers, LSP Servers, and Agent Teams.

## Why this plugin?

[Claude Code](https://claude.ai/code) is Anthropic's AI coding agent for the terminal. It offers multiple automation mechanisms: **skills**, **hooks**, **subagents**, **permissions**, **CLAUDE.md**, **custom commands**, **MCP servers**, **LSP servers**, and **agent teams**. Each serves a different purpose, but choosing the right one isn't always obvious.

**Common questions:**
- Should I use a hook or a skill?
- When do I need a subagent vs a regular skill?
- How do I enforce a rule that Claude MUST follow, not just "should" follow?
- What if I use `--dangerously-skip-permissions`?
- When should I set up an MCP server vs a hook?
- Do I need an agent team or just a subagent?

This plugin acts as an expert advisor. You describe what you want to automate, it interviews you to understand your exact needs, then creates the right files in the right places.

## Installation

```bash
/plugin marketplace add elmisi/claude-code-automation
/plugin install claude-code-automation
```

Then restart Claude Code to activate the plugin.

## Usage

```bash
/automate <your topic>
```

### Examples

```bash
/automate semantic versioning on every commit
/automate block push without explicit approval
/automate TUI project conventions
/automate security review for all PRs
/automate API design guidelines
/automate integrate GitHub tools via MCP
/automate set up TypeScript language server
```

## See it in action

> `/automate run tests before every commit`

The plugin interviews you to understand exactly what you need:

**Q: When should this happen?**
&rarr; *Always, on every commit*

**Q: Must it be guaranteed, or just a guideline?**
&rarr; *Guaranteed — block the commit if tests fail*

**Q: Should Claude decide which tests to run?**
&rarr; *Yes, based on the changed files*

### Decision: Hook + Skill

> *"A Skill alone won't work — Claude can skip skills. You need a **Hook** to guarantee tests run on every commit. But since Claude should intelligently pick which tests based on changed files, you also need a **Skill** for the logic. I'll create both."*

**Files created:**

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Hook: blocks `git commit` unless tests pass |
| `~/.claude/skills/test-runner/SKILL.md` | Skill: analyzes changes, picks relevant tests |

Both files are validated against schemas and registered for easy management (`/automate list`).

**The twist:** had you answered *"just a guideline"* instead, the plugin would create a single `CLAUDE.md` rule — no hooks, no skills. Same topic, different needs, completely different automation.

---

## Managing Automations

All automations created by this plugin are tracked in a registry (`~/.claude/automations-registry.json`). You can manage them with sub-commands:

| Command | Description |
|---------|-------------|
| `/automate list` | List all tracked automations with options to view, edit, delete, or export |
| `/automate edit <name>` | Modify an existing automation (name, description, behavior, scope) |
| `/automate delete <name>` | Remove an automation with confirmation |
| `/automate export [file]` | Export all automations to a portable JSON file |
| `/automate import <file>` | Import automations from another machine with conflict resolution |

### Export/Import Example

```bash
# On machine A: export your automations
/automate export ~/my-automations.json

# Copy the file to machine B, then import
/automate import ~/my-automations.json
```

When importing, you'll be asked how to handle conflicts if an automation with the same name already exists.

## How it works

1. **Auto-updates**: Fetches the latest Claude Code documentation to stay current with new features
2. **Interviews you**: Asks specific questions about timing, scope, and requirements
3. **Decides**: Uses a decision matrix to pick the right automation type
4. **Explains**: Tells you what it chose and why, with alternatives considered
5. **Creates**: Generates the necessary files in the correct locations
6. **Validates**: Checks all files against schemas before writing
7. **Verifies**: Ensures all components of a combination are complete
8. **Tests**: Shows you how to test and use your new automation

## Decision Matrix

| Need | Solution |
|------|----------|
| Must happen EVERY time, no exceptions | Hook |
| Control what Claude can/cannot do | Permissions |
| Domain knowledge applied automatically | Skill |
| Complex workflow invoked manually | Skill (with `disable-model-invocation: true`) |
| Separate context for analysis/review | Subagent |
| Simple global rule | CLAUDE.md |
| Shortcut for frequent prompt | Custom Command |
| External tool/service integration | MCP Server |
| Code intelligence (diagnostics, hover) | LSP Server |
| Parallel multi-agent orchestration | Agent Team (experimental) |

## Common Combinations

- **Hook + Skill**: Guaranteed execution (hook) with complex logic (skill)
- **Permissions + CLAUDE.md**: Technical block + explanation of why
- **Skill + Subagent**: Workflow definition + isolated deep analysis
- **MCP Server + Skill**: External tool access + workflow orchestration
- **Agent Team + Skill**: Multi-agent orchestration + domain knowledge

## Key Insights

### Hooks vs Skills
- **Hooks** are scripts that run automatically at specific events. They're deterministic and guaranteed.
- **Skills** are knowledge/workflows that Claude applies with intelligence. They're advisory.
- Use hooks when something MUST happen. Use skills when Claude needs to think.

### Permissions Caveat
If you use `--dangerously-skip-permissions`, permission rules won't work. The plugin will suggest using hooks as an alternative for guaranteed blocks.

### MCP Servers
MCP servers expose external tools to Claude via the Model Context Protocol. Tools appear as `mcp__<server>__<tool>` and can be matched in hook matchers. Supports `stdio` (local processes) and `sse` (remote HTTP) transports.

### LSP Servers
LSP servers provide code intelligence features (diagnostics, hover, completions) via the Language Server Protocol. The language server binary must be installed separately.

### Agent Teams (Experimental)
Agent teams enable parallel multi-agent orchestration. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. The feature is experimental and may change.

### Subagents for Clean Context
Subagents run in isolated context windows. Use them for:
- Code review (unbiased, separate from the code that was just written)
- Deep investigation (reads many files without polluting your main context)
- Specialized analysis (security, performance, etc.)

## Testing

Tests are split into three categories:

| Type | Command | Tests | Description |
|------|---------|-------|-------------|
| Structure | `./tests/scripts/run-tests.sh structure` | 39 | File structure, JSON validity, fixture validation, version sync, negative validation |
| Fixture | `./tests/scripts/run-tests.sh e2e` | 20 | Creates expected outputs in sandbox and validates their structure |
| Interactive | `./tests/scripts/run-tests.sh interactive` | 5 | Runs actual Claude commands to test the skill end-to-end (consumes tokens) |

**Note**: Structure and fixture tests are deterministic and run in CI. Interactive tests are qualitative smoke tests that verify the skill produces reasonable output with a real Claude instance. They are not CI-grade deterministic tests.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture overview, and how to add new automation types.

## License

MIT
