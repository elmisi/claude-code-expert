---
name: setup-automation
description: Expert advisor that helps decide and create the right Claude Code automation
disable-model-invocation: true
---

# Claude Code Expert - Setup Automation

The user wants to automate: $ARGUMENTS

---

## Step 0: Load schemas and check for updates (semi-automatic)

### 0.1 Load validation schemas
Read the schema files from this plugin to know what values are valid:
- `plugin/schemas/hooks.json` - Valid hook events, types, matchers
- `plugin/schemas/skills.json` - Skill frontmatter requirements
- `plugin/schemas/subagents.json` - Subagent configuration
- `plugin/schemas/permissions.json` - Permission patterns
- `plugin/schemas/custom-commands.json` - Custom command format

**CRITICAL: Only use values listed in these schemas. Never invent event names or fields.**

### 0.2 Check for documentation updates
Fetch the official documentation to check for updates:
- https://code.claude.com/docs/en/hooks-guide
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/settings

Compare with `plugin/docs/claude-code-reference.md`. If there are significant differences:
1. Show the diff to the user
2. Ask for confirmation before updating
3. Update schemas if new events/features were added

---

## Step 1: In-depth interview

Use AskUserQuestion to clarify the use case. Ask specific questions:

### Timing and frequency
- When should this automation happen?
  - Always, on every specific action (e.g., every commit, every edit)
  - Only in certain contexts (e.g., only for TUI projects)
  - Only on explicit user request

### Nature of automation
- Must it be guaranteed/deterministic (MUST happen) or is it a guideline (SHOULD happen)?
- Does it need Claude's intelligence/decisions or can a script/command suffice?
- Can it fail silently or must it block the operation?

### Scope
- Does it apply to all projects or just this one?
- Does it apply to the whole project or only certain types of files/work?
- Should other team developers follow the same rule?

### Input/Output
- Are parameters/arguments needed?
- Should it produce files, output, or modify configurations?

---

## Step 2: Analysis and decision

Based on the answers, use this decision matrix:

| Criterion | Hook | Skill | Skill (manual) | Subagent | Permissions | CLAUDE.md | Custom Cmd |
|-----------|------|-------|----------------|----------|-------------|-----------|------------|
| Must happen ALWAYS without exceptions | YES | no | no | no | no | no | no |
| Rule about what Claude can/cannot do | no | no | no | no | YES | maybe | no |
| Domain knowledge applied automatically | no | YES | no | no | no | maybe | no |
| Complex workflow invoked manually | no | no | YES | no | no | no | no |
| Needs separate/isolated context | no | no | no | YES | no | no | no |
| Independent review/analysis | no | no | no | YES | no | no | no |
| Simple global rule | no | no | no | no | no | YES | no |
| Shortcut for frequent prompt | no | no | no | no | no | no | YES |

### Common combinations

- **Hook + Skill**: When it must always happen (hook) but requires complex logic (skill)
- **Skill + Subagent**: When the skill defines the workflow but needs a subagent for deep analysis
- **Permissions + CLAUDE.md**: Permissions for technical block, CLAUDE.md to explain why

---

## Step 3: Explain the decision

Before creating, explain to the user:
1. What you decided to create and why
2. Alternatives considered and why they were discarded
3. How it will work in practice
4. Any limitations or considerations

Ask for confirmation before proceeding.

---

## Step 4: Create the files with VALIDATION

**CRITICAL: Before creating any file, validate against the schemas.**

### For Hook

**ONLY use these valid events** (from `schemas/hooks.json`):
- `SessionStart` - Session begins (matchers: startup, resume, clear, compact)
- `SessionEnd` - Session ends (matchers: clear, logout, prompt_input_exit, other)
- `UserPromptSubmit` - When user submits a prompt (no matcher)
- `PreToolUse` - Before a tool executes (matchers: Bash, Edit, Write, Edit|Write, mcp__.*)
- `PostToolUse` - After a tool succeeds (same matchers as PreToolUse)
- `PostToolUseFailure` - After a tool fails
- `PermissionRequest` - When permission dialog appears
- `Notification` - When Claude needs attention (matchers: permission_prompt, idle_prompt)
- `Stop` - When Claude finishes responding (no matcher)
- `PreCompact` - Before context compaction (matchers: manual, auto)
- `SubagentStart`, `SubagentStop` - Subagent lifecycle

**NEVER use these (they don't exist):**
- PreCommit, PostCommit, PreBash, PostBash, PreEdit, PostEdit, BeforeToolUse, AfterToolUse

**Correct structure:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

**Exit codes:**
- Exit 0 = allow the action
- Exit 2 = block the action (stderr becomes Claude's feedback)

**Use templates from `plugin/templates/hook-*.json` as a base.**

### For Skill

Location: `.claude/skills/[name]/SKILL.md` (project) or `~/.claude/skills/[name]/SKILL.md` (global)

Required frontmatter:
```yaml
---
name: skill-name
description: What this skill does
disable-model-invocation: true|false
---
```

Use template from `plugin/templates/skill.md`.

### For Subagent

Location: `.claude/agents/[name].md` (project) or `~/.claude/agents/[name].md` (global)

Required frontmatter:
```yaml
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash
model: sonnet
---
```

Valid tools: Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch, Task, NotebookEdit
Valid models: opus, sonnet, haiku

Use template from `plugin/templates/subagent.md`.

### For Permissions

Location: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Bash(git commit *)"],
    "deny": ["Bash(git push *)"]
  }
}
```

**Warning:** Does NOT work with `--dangerously-skip-permissions`. Use Hooks instead for guaranteed blocks.

### For Custom Command

Location: `.claude/settings.json`

```json
{
  "customCommands": {
    "name": "prompt text"
  }
}
```

### For CLAUDE.md

Add the rule to `./CLAUDE.md` (project) or `~/.claude/CLAUDE.md` (global).

---

## Step 5: Validate before writing

Before creating any configuration file:

1. **For hooks**: Verify event name is in the valid list
2. **For hooks**: Verify structure has nested `hooks` array with `type` and `command`
3. **For skills/subagents**: Verify required frontmatter fields
4. **For subagents**: Verify tools and model are valid

If validation fails, show the error and do NOT create the file.

---

## Step 6: Verify and instruct

After creating:
1. Show the created files
2. Explain how to test/use the automation
3. Suggest possible future improvements
4. If it's a skill/subagent, show the command to invoke it

---

## Important notes

- If the user uses `--dangerously-skip-permissions`, Permissions won't work. Suggest Hook as an alternative for blocks.
- CLAUDE.md instructions are advisory, not guaranteed. If certainty is needed, use Hook.
- Hooks are scripts, they don't have access to Claude's intelligence. For complex logic, combine Hook + Skill.
- Subagents consume extra tokens but preserve the main context.
- Always validate configurations before creating files to prevent errors like the invalid `PreCommit` event.
