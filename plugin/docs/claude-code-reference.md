# Claude Code Reference Documentation

Last updated: 2025-02-04

This file contains the reference documentation for Claude Code automation mechanisms.
For the authoritative source of valid values, see the schema files in `plugin/schemas/`.

---

## Overview

Claude Code offers several automation mechanisms:

1. **Hooks** - Deterministic script execution at specific lifecycle events
2. **Skills** - Domain knowledge and workflows
3. **Subagents** - Specialized assistants with isolated context
4. **Permissions** - Control what tools Claude can use
5. **CLAUDE.md** - Persistent instructions loaded every session
6. **Custom Commands** - Shortcut aliases for prompts

---

## Hooks

Location: `.claude/settings.json` or `~/.claude/settings.json`

### Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "optional_pattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-shell-command"
          }
        ]
      }
    ]
  }
}
```

### Valid Events

| Event | Description | Matcher Values |
|-------|-------------|----------------|
| `SessionStart` | Session begins | `startup`, `resume`, `clear`, `compact` |
| `SessionEnd` | Session ends | `clear`, `logout`, `prompt_input_exit`, `other` |
| `UserPromptSubmit` | User submits prompt | (no matcher) |
| `PreToolUse` | Before tool executes | Tool names: `Bash`, `Edit`, `Write`, `Edit\|Write`, `mcp__.*` |
| `PostToolUse` | After tool succeeds | Same as PreToolUse |
| `PostToolUseFailure` | After tool fails | Same as PreToolUse |
| `PermissionRequest` | Permission dialog appears | Tool names |
| `Notification` | Claude needs attention | `permission_prompt`, `idle_prompt`, `auth_success` |
| `Stop` | Claude finishes responding | (no matcher) |
| `PreCompact` | Before context compaction | `manual`, `auto` |
| `SubagentStart` | Subagent spawned | Agent type |
| `SubagentStop` | Subagent finished | Agent type |

### Invalid Events (DO NOT USE)

These event names do **NOT** exist:
- `PreCommit`, `PostCommit`
- `PreBash`, `PostBash`
- `PreEdit`, `PostEdit`
- `BeforeToolUse`, `AfterToolUse`

### Hook Types

| Type | Description |
|------|-------------|
| `command` | Execute a shell command |
| `prompt` | Single-turn LLM evaluation (Haiku by default) |
| `agent` | Multi-turn verification with tool access |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow/proceed |
| `2` | Block the action (stderr becomes Claude's feedback) |
| Other | Allow, but log error |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_TOOL_INPUT` | JSON string of tool input |
| `CLAUDE_PROJECT_DIR` | Project directory path |
| `CLAUDE_SESSION_ID` | Current session ID |

### Example: Block git push

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'git push'; then echo 'Blocked: requires authorization' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

**Use for**: Actions that MUST happen every time, no exceptions. Deterministic, not advisory.

---

## Skills

Location: `.claude/skills/[name]/SKILL.md`

### Structure

```markdown
---
name: skill-name
description: What this skill does
disable-model-invocation: true|false
---

Content here...
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier, used for `/skill-name` invocation |
| `description` | Yes | Brief description |
| `disable-model-invocation` | No | If `true`, only invoked via `/skill-name`. Default: `false` |

### Variables

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | Replaced with user input after `/skill-name` |

**Use for**: Domain knowledge, workflows, conventions that apply in specific contexts

---

## Subagents

Location: `.claude/agents/[name].md`

### Structure

```markdown
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash
model: sonnet
---

System prompt for the agent...
```

### Frontmatter Fields

| Field | Required | Valid Values |
|-------|----------|--------------|
| `name` | Yes | Agent identifier |
| `description` | Yes | Brief description |
| `tools` | No | `Read`, `Grep`, `Glob`, `Bash`, `Edit`, `Write`, `WebFetch`, `WebSearch`, `Task`, `NotebookEdit` |
| `model` | No | `opus`, `sonnet`, `haiku` (default: sonnet) |

**Use for**:
- Tasks requiring separate/clean context
- Deep investigation without polluting main context
- Independent code review
- Specialized analysis (security, performance, etc.)

**Invocation**: `Use a subagent to...` or `Use the [name] agent to...`

---

## Permissions

Location: `.claude/settings.json`

### Structure

```json
{
  "permissions": {
    "allow": ["Bash(git commit *)"],
    "deny": ["Bash(git push *)"]
  }
}
```

### Pattern Syntax

Format: `ToolName(argument_pattern)`

Examples:
- `Bash(git commit *)` - Allow git commit with any message
- `Bash(npm test)` - Allow npm test
- `Edit(*.test.js)` - Allow editing test files

**Use for**: Controlling what Claude can do at the tool level

**Warning**: Does NOT work with `--dangerously-skip-permissions`. Use Hooks instead.

---

## CLAUDE.md

Location: `./CLAUDE.md` (project) or `~/.claude/CLAUDE.md` (global)

**Use for**:
- Global rules that apply to all sessions
- Instructions Claude can't infer from code
- Keep concise - bloated files get ignored

**Note**: Advisory, not guaranteed. Claude may not follow if context is cluttered. For guaranteed execution, use Hooks.

---

## Custom Commands

Location: `.claude/settings.json`

### Structure

```json
{
  "customCommands": {
    "test": "Run all tests and fix failures",
    "lint": "Run linter and fix all issues"
  }
}
```

**Use for**: Simple shortcuts, no parameters, one-line prompts

**Limitations**:
- No parameters (use Skills for parameterized workflows)
- Single-line prompts only
- Just text replacement, no logic

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

---

## Common Mistakes to Avoid

1. **Invalid hook events**: Always check `schemas/hooks.json` for valid event names
2. **Wrong hook structure**: Use nested `hooks` array with `matcher`, `type`, `command`
3. **Permissions with skip-permissions**: Use Hooks instead for guaranteed blocks
4. **Bloated CLAUDE.md**: Keep it concise, Claude may ignore if too long
