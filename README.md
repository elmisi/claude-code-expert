# claude-code-expert

> An expert advisor plugin for Claude Code that helps you decide and create the right automation for your needs.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why this plugin?

Claude Code offers multiple automation mechanisms: **skills**, **hooks**, **subagents**, **permissions**, **CLAUDE.md**, and **custom commands**. Each serves a different purpose, but choosing the right one isn't always obvious.

**Common questions:**
- Should I use a hook or a skill?
- When do I need a subagent vs a regular skill?
- How do I enforce a rule that Claude MUST follow, not just "should" follow?
- What if I use `--dangerously-skip-permissions`?

This plugin acts as an expert advisor. You describe what you want to automate, it interviews you to understand your exact needs, then creates the right files in the right places.

## Installation

```bash
claude plugin add claude-code-expert
```

## Usage

```bash
/setup-automation <your topic>
```

### Examples

```bash
/setup-automation semantic versioning on every commit
/setup-automation block push without explicit approval
/setup-automation TUI project conventions
/setup-automation security review for all PRs
/setup-automation API design guidelines
```

## How it works

1. **Auto-updates**: Fetches the latest Claude Code documentation to stay current with new features
2. **Interviews you**: Asks specific questions about timing, scope, and requirements
3. **Decides**: Uses a decision matrix to pick the right automation type
4. **Explains**: Tells you what it chose and why, with alternatives considered
5. **Creates**: Generates the necessary files in the correct locations
6. **Verifies**: Shows you how to test and use your new automation

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

## Common Combinations

- **Hook + Skill**: Guaranteed execution (hook) with complex logic (skill)
- **Permissions + CLAUDE.md**: Technical block + explanation of why
- **Skill + Subagent**: Workflow definition + isolated deep analysis

## Key Insights

### Hooks vs Skills
- **Hooks** are scripts that run automatically at specific events. They're deterministic and guaranteed.
- **Skills** are knowledge/workflows that Claude applies with intelligence. They're advisory.
- Use hooks when something MUST happen. Use skills when Claude needs to think.

### Permissions Caveat
If you use `--dangerously-skip-permissions`, permission rules won't work. The plugin will suggest using hooks as an alternative for guaranteed blocks.

### Subagents for Clean Context
Subagents run in isolated context windows. Use them for:
- Code review (unbiased, separate from the code that was just written)
- Deep investigation (reads many files without polluting your main context)
- Specialized analysis (security, performance, etc.)

## Contributing

Contributions are welcome! Please open an issue or PR.

## License

MIT
