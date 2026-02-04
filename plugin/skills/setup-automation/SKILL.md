---
name: setup-automation
description: Expert advisor that helps decide and create the right Claude Code automation
disable-model-invocation: true
---

# Claude Code Expert - Setup Automation

The user wants to automate: $ARGUMENTS

---

## Step 0: Update documentation

Before proceeding, update your knowledge:

1. Fetch the official documentation:
   - https://code.claude.com/docs/en/best-practices
   - https://code.claude.com/docs/en/skills
   - https://code.claude.com/docs/en/hooks-guide
   - https://code.claude.com/docs/en/sub-agents
   - https://code.claude.com/docs/en/settings

2. Update `docs/claude-code-reference.md` in the plugin with any relevant updates for choosing between skill, hook, subagent, permissions, CLAUDE.md and custom commands.

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
| Must happen ALWAYS without exceptions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Rule about what Claude can/cannot do | ❌ | ❌ | ❌ | ❌ | ✅ | ⚠️ | ❌ |
| Domain knowledge applied automatically | ❌ | ✅ | ❌ | ❌ | ❌ | ⚠️ | ❌ |
| Complex workflow invoked manually | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Needs separate/isolated context | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Independent review/analysis | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Simple global rule | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Shortcut for frequent prompt | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

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

## Step 4: Create the files

After confirmation, create the necessary files:

### For Hook
```json
// .claude/settings.json
{
  "hooks": {
    "[eventType]": [
      {
        "command": "...",
        "description": "..."
      }
    ]
  }
}
```

Available events: `preBash`, `postBash`, `preEdit`, `postEdit`, `preWrite`, `postWrite`, `beforeCommit`, `afterCommit`

### For Skill
```markdown
// .claude/skills/[name]/SKILL.md
---
name: [name]
description: [description]
disable-model-invocation: [true for manual workflow, false for automatic]
---
[content]
```

### For Subagent
```markdown
// .claude/agents/[name].md
---
name: [name]
description: [description]
tools: [tool list: Read, Grep, Glob, Bash, Edit, Write]
model: [opus|sonnet|haiku]
---
[specialized system prompt]
```

### For Permissions
```json
// .claude/settings.json
{
  "permissions": {
    "allow": ["..."],
    "deny": ["..."]
  }
}
```

### For Custom Command
```json
// .claude/settings.json
{
  "customCommands": {
    "[name]": "[prompt]"
  }
}
```

### For CLAUDE.md
Add the rule to the CLAUDE.md file in the project root.

---

## Step 5: Verify and instruct

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
