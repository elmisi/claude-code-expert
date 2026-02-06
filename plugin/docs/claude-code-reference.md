# Claude Code Reference Documentation

Last updated: 2026-02-06

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
7. **MCP Servers** - External tool integration via Model Context Protocol
8. **LSP Servers** - Code intelligence via Language Server Protocol
9. **Agent Teams** - Multi-Claude orchestration (experimental)

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
| `SessionEnd` | Session ends | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `UserPromptSubmit` | User submits prompt | (no matcher) |
| `PreToolUse` | Before tool executes | Tool names: `Bash`, `Edit`, `Write`, `Edit\|Write`, `mcp__.*` |
| `PostToolUse` | After tool succeeds | Same as PreToolUse |
| `PostToolUseFailure` | After tool fails | Same as PreToolUse |
| `PermissionRequest` | Permission dialog appears | Tool names |
| `Notification` | Claude needs attention | `permission_prompt`, `idle_prompt`, `auth_success` |
| `Stop` | Claude finishes responding | (no matcher) |
| `PreCompact` | Before context compaction | `manual`, `auto` |
| `SubagentStart` | Subagent spawned | Agent type (e.g. `code-reviewer`, `general-purpose`) |
| `SubagentStop` | Subagent finished | Agent type (e.g. `code-reviewer`, `general-purpose`) |

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

### Hook Handler Fields

| Field | Type | Description |
|-------|------|-------------|
| `async` | boolean | Run in background, `command` type only |
| `timeout` | integer | Per-hook timeout in milliseconds |
| `statusMessage` | string | Custom spinner text shown during execution |
| `model` | string | Model override for `prompt` and `agent` hook types |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow/proceed |
| `2` | Block the action (stderr becomes Claude's feedback) |
| Other | Allow, but log error |

### Advanced Capabilities

- **PreToolUse `updatedInput`**: Hooks on `PreToolUse` can return a JSON object with an `updatedInput` key on stdout. This allows hooks to modify the tool's input before execution (e.g., rewriting file paths, adding flags).
- **PermissionRequest `decision`**: Hooks on `PermissionRequest` can return a JSON object with a `decision` key (`"allow"` or `"deny"`) on stdout. This allows hooks to programmatically control permission decisions without user interaction.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_TOOL_INPUT` | JSON string of tool input |
| `CLAUDE_PROJECT_DIR` | Project directory path |
| `CLAUDE_SESSION_ID` | Current session ID |
| `CLAUDE_ENV_FILE` | Path to a file where hooks can write `KEY=VALUE` pairs to set environment variables for subsequent hooks |
| `CLAUDE_PLUGIN_ROOT` | Root directory of the plugin that registered the hook |
| `CLAUDE_CODE_REMOTE` | Set to `1` when running in a remote/headless environment |

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
| `context` | No | Set to `fork` to run the skill in a forked conversation context |
| `hooks` | No | Object defining hooks scoped to this skill (same structure as global hooks) |

### Variables

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | Replaced with user input after `/skill-name` |

**Note**: Skills support hot-reloading. Changes to SKILL.md files are picked up automatically without restarting Claude Code.

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
| `tools` | No | `Read`, `Grep`, `Glob`, `Bash`, `Edit`, `Write`, `WebFetch`, `WebSearch`, `Task`, `NotebookEdit`, `AskUserQuestion`, `TaskOutput`, `ExitPlanMode`, `MCPSearch` |
| `model` | No | `opus`, `sonnet`, `haiku`, `inherit` (default: inherit) |
| `disallowedTools` | No | List of tools the agent cannot use |
| `permissionMode` | No | Permission mode for the agent's tool usage |
| `skills` | No | List of skills available to the agent |
| `hooks` | No | Object defining hooks scoped to this agent |
| `memory` | No | Persistent memory configuration for the agent |

### Built-in Agents

Claude Code includes several built-in agents:

| Agent | Description |
|-------|-------------|
| `Explore` | Codebase exploration and analysis |
| `Plan` | Planning and task decomposition |
| `general-purpose` | General-purpose subagent for delegated tasks |
| `Bash` | Shell command execution agent |

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

## MCP Servers

Location: `.mcp.json` (project) or `~/.claude.json` (global)

### Structure

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@my-org/my-mcp-server"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

### Valid Types

| Type | Required Fields | Description |
|------|----------------|-------------|
| `stdio` | `command` | Communicates via stdin/stdout. Requires `command`, optional `args` and `env` |
| `sse` | `url` | Communicates via Server-Sent Events. Requires `url` |

### Tool Naming

MCP tools are exposed with the naming convention: `mcp__<server>__<tool>`

For example, a server named `my-server` providing a tool named `search` would be available as `mcp__my-server__search`. Use this naming pattern when referencing MCP tools in hook matchers (e.g., `"matcher": "mcp__my-server__.*"`).

**Use for**: Integrating external tools and services (databases, APIs, custom tooling) into Claude Code sessions

**Limitation**: Background subagents cannot use MCP tools.

---

## LSP Servers

Location: `.lsp.json` (project) or `~/.claude/lsp.json` (global)

### Structure

```json
{
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "languages": ["typescript", "javascript"]
    }
  }
}
```

### Required Fields

| Field | Description |
|-------|-------------|
| `command` | The language server executable to run |
| `languages` | Array of language identifiers this server handles |

**Use for**: Code intelligence features such as diagnostics, hover information, and completions integrated into Claude Code's workflow

**Limitation**: The language server binary must be installed separately on the system. Claude Code does not install language servers automatically.

---

## Agent Teams

Location: `~/.claude/teams/{team-name}/config.json`

### Structure

```json
{
  "name": "my-team",
  "description": "A team for parallel feature development",
  "agents": [
    {
      "name": "frontend",
      "description": "Handles UI components",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    },
    {
      "name": "backend",
      "description": "Handles API endpoints",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    }
  ],
  "settings": {
    "displayMode": "split",
    "delegateMode": "auto",
    "requirePlanApproval": true
  }
}
```

### Required Fields

| Field | Description |
|-------|-------------|
| `name` | Team identifier |
| `description` | Brief description of the team's purpose |
| `agents` | Array of agent configurations |

### Settings

| Setting | Description |
|---------|-------------|
| `displayMode` | How agent outputs are displayed (`split`, `sequential`, `unified`) |
| `delegateMode` | How tasks are delegated to agents (`auto`, `manual`) |
| `requirePlanApproval` | Whether the orchestrator must get approval before delegating |

**Use for**: Parallel multi-agent orchestration where multiple Claude instances work on different parts of a task simultaneously

**Warning**: This is an experimental feature. You must set the environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to enable it.

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
| External tool access | MCP Server |
| Code intelligence | LSP Server |
| Parallel multi-agent work | Agent Team (experimental) |

---

## Common Mistakes to Avoid

1. **Invalid hook events**: Always check `schemas/hooks.json` for valid event names
2. **Wrong hook structure**: Use nested `hooks` array with `matcher`, `type`, `command`
3. **Permissions with skip-permissions**: Use Hooks instead for guaranteed blocks
4. **Bloated CLAUDE.md**: Keep it concise, Claude may ignore if too long
5. **Using Agent Teams without the experimental flag**: You must set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` or the feature will silently not work
6. **Forgetting that MCP tools need mcp__ prefix in hook matchers**: MCP tools are named `mcp__<server>__<tool>`, so hook matchers must use this full prefix (e.g., `mcp__my-server__.*`)
