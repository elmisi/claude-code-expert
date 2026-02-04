# Claude Code Reference Documentation

Last updated: 2025-02-04

This file is automatically updated by the setup-automation skill when invoked.

---

## Overview

Claude Code offers several automation mechanisms:

1. **Skills** - Domain knowledge and workflows
2. **Hooks** - Deterministic script execution at specific events
3. **Subagents** - Specialized assistants with isolated context
4. **Permissions** - Control what tools Claude can use
5. **CLAUDE.md** - Persistent instructions loaded every session
6. **Custom Commands** - Shortcut aliases for prompts

---

## Skills

Location: `.claude/skills/[name]/SKILL.md`

```markdown
---
name: skill-name
description: What this skill does
disable-model-invocation: true|false
---
Content here...
```

- `disable-model-invocation: false` (default): Claude applies automatically when relevant
- `disable-model-invocation: true`: Only invoked manually via `/skill-name`
- Support `$ARGUMENTS` for parameters

**Use for**: Domain knowledge, workflows, conventions that apply in specific contexts

---

## Hooks

Location: `.claude/settings.json`

```json
{
  "hooks": {
    "eventType": [
      {
        "command": "script or command",
        "description": "what it does"
      }
    ]
  }
}
```

Event types:
- `preBash`, `postBash`
- `preEdit`, `postEdit`
- `preWrite`, `postWrite`
- `beforeCommit`, `afterCommit`

**Use for**: Actions that MUST happen every time, no exceptions. Deterministic, not advisory.

**Note**: Hooks are scripts, they don't have Claude's intelligence. For complex logic, combine Hook + Skill.

---

## Subagents

Location: `.claude/agents/[name].md`

```markdown
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash, Edit, Write
model: opus|sonnet|haiku
---
System prompt for the agent...
```

**Use for**:
- Tasks requiring separate/clean context
- Deep investigation without polluting main context
- Independent code review
- Specialized analysis (security, performance, etc.)

Invoke with: `Use a subagent to...` or `Use the [name] agent to...`

---

## Permissions

Location: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Bash(git commit *)"],
    "deny": ["Bash(git push *)"]
  }
}
```

**Use for**: Controlling what Claude can do at the tool level

**Note**: Does NOT work with `--dangerously-skip-permissions`. Use Hooks instead for guaranteed blocks.

---

## CLAUDE.md

Location: Project root `./CLAUDE.md` or `~/.claude/CLAUDE.md`

**Use for**:
- Global rules that apply to all sessions
- Instructions Claude can't infer from code
- Keep concise - bloated files get ignored

**Note**: Advisory, not guaranteed. Claude may not follow if context is cluttered.

---

## Custom Commands

Location: `.claude/settings.json`

```json
{
  "customCommands": {
    "test": "Run all tests and fix failures",
    "lint": "Run linter and fix all issues"
  }
}
```

**Use for**: Simple shortcuts, no parameters, one-line prompts

---

## Decision Quick Reference

| If you need... | Use |
|----------------|-----|
| Guaranteed execution | Hook |
| Tool restrictions | Permissions (or Hook if using skip-permissions) |
| Context-aware knowledge | Skill |
| Manual workflow | Skill + disable-model-invocation |
| Isolated analysis | Subagent |
| Global simple rule | CLAUDE.md |
| Prompt shortcut | Custom Command |
