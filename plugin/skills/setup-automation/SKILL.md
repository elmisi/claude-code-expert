---
name: setup-automation
description: Expert advisor that helps decide and create the right Claude Code automation
disable-model-invocation: true
---

# Claude Code Expert - Setup Automation

Arguments: $ARGUMENTS

---

## Command Router

Parse `$ARGUMENTS` to determine the action:

| Pattern | Action |
|---------|--------|
| `list` | Go to **List Automations** |
| `edit <name>` | Go to **Edit Automation** |
| `delete <name>` | Go to **Delete Automation** |
| `export [file]` | Go to **Export Automations** |
| `import <file>` | Go to **Import Automations** |
| Anything else | Go to **Create New Automation** |

---

# List Automations

Read the registry file: `~/.claude/automations-registry.json`

If it doesn't exist, say:
> "No automations registry found. Create automations with `/setup-automation <description>` to start tracking."

If it exists, display a table:

```
┌─────────────────┬────────┬────────┬─────────────────────────────────────┐
│ Name            │ Type   │ Scope  │ Description                         │
├─────────────────┼────────┼────────┼─────────────────────────────────────┤
│ icon-prompt     │ skill  │ global │ Generate prompts for AI image gen.  │
└─────────────────┴────────┴────────┴─────────────────────────────────────┘
```

Then use AskUserQuestion to offer actions:

```
What would you like to do?
- View details of an automation
- Edit an automation
- Delete an automation
- Export all automations
- Create a new automation
- Nothing, just browsing
```

Handle the selected action accordingly.

---

# Edit Automation

Arguments: `edit <name>`

1. Read the registry to find the automation by name
2. If not found, show error and list available automations
3. If found, read the actual file from the path in the registry
4. Use AskUserQuestion to ask what to change:
   - Name
   - Description
   - Behavior/content
   - Scope (move from project to global or vice versa)
5. Make the changes to the file
6. Update the registry with new `modified` timestamp
7. Show the diff and confirm

---

# Delete Automation

Arguments: `delete <name>`

1. Read the registry to find the automation by name
2. If not found, show error and list available automations
3. If found, show the automation details and ask for confirmation
4. Use AskUserQuestion with options:
   - "Yes, delete it"
   - "No, keep it"
5. If confirmed:
   - Delete the file(s) (for skills: entire folder, for hooks: remove from settings.json)
   - Remove from registry
   - Show confirmation
6. If not confirmed, cancel

---

# Export Automations

Arguments: `export [file]`

Default file: `~/.claude/automations-export.json`

1. Read the registry
2. For each automation, read its content
3. Create export file:

```json
{
  "exportVersion": "1.0",
  "exportDate": "YYYY-MM-DD",
  "source": "machine-name or user identifier",
  "automations": [
    {
      "name": "icon-prompt",
      "type": "skill",
      "scope": "global",
      "description": "...",
      "files": [
        {
          "relativePath": "SKILL.md",
          "content": "--- full file content ---"
        }
      ]
    }
  ]
}
```

4. Write the file
5. Show summary: "Exported N automations to <file>"
6. Suggest: "You can import this on another machine with `/setup-automation import <file>`"

---

# Import Automations

Arguments: `import <file>`

1. Read the import file
2. Validate format (version, required fields)
3. For each automation in the file:
   a. Check if it already exists (by name)
   b. If exists, use AskUserQuestion:
      - "Overwrite existing"
      - "Rename to <name>-imported"
      - "Skip this automation"
   c. If not exists, show preview and ask confirmation
4. Create the files in appropriate locations
5. Add to registry with `created-by: setup-automation` marker
6. Show summary of imported automations

---

# Create New Automation

(Original workflow - proceed if $ARGUMENTS is not a known command)

---

## ⚠️ CRITICAL RULE: COMPLETE ALL COMPONENTS

**This skill MUST create EVERYTHING it promises. Partial implementations are FORBIDDEN.**

If you decide "Hook + Skill is needed":
- You MUST create the hook AND the skill
- You MUST test that both work
- You MUST NOT finish until both are verified

If ANY component fails:
- FIX IT before proceeding
- DO NOT remove it and continue
- DO NOT leave it for "later"

**An incomplete automation is worse than no automation.**

---

## Step 0: Load schemas and check for updates

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

### Common combinations (MUST create ALL components)

**Hook + Skill** - When it must always happen (hook) but requires complex logic (skill)
- REQUIRED: Hook script in `~/.claude/scripts/`
- REQUIRED: Hook entry in `settings.json` with VALID event (PreToolUse, PostToolUse, etc.)
- REQUIRED: Skill file in `~/.claude/skills/[name]/SKILL.md`
- REQUIRED: Both registered with `relatedHook`/`relatedSkill` links

**Skill + Subagent** - When the skill defines the workflow but needs a subagent for deep analysis
- REQUIRED: Skill file
- REQUIRED: Subagent file in `~/.claude/agents/[name].md`
- REQUIRED: Both registered with links

**Permissions + CLAUDE.md** - Permissions for technical block, CLAUDE.md to explain why
- REQUIRED: Permission rule in `settings.json`
- REQUIRED: Rule explanation in `CLAUDE.md`
- REQUIRED: Both registered

---

## Step 3: Explain the decision

Before creating, explain to the user:
1. What you decided to create and why
2. Alternatives considered and why they were discarded
3. How it will work in practice
4. Any limitations or considerations

**If the decision involves a COMBINATION (e.g., Hook + Skill), explicitly list ALL components:**

```
CREATION PLAN:
[ ] Component 1: Hook (PreToolUse → Bash) - enforces the rule
[ ] Component 2: Skill (semver) - provides the logic
```

**CRITICAL: You MUST create ALL components. Do NOT proceed to Step 6 until all boxes are checked.**

Ask for confirmation before proceeding.

---

## Step 4: Create the files with VALIDATION

**CRITICAL: Before creating any file, validate against the schemas.**

### Registry tracking

**Every automation created MUST be registered.**

After creating the files, add to `~/.claude/automations-registry.json`:

```json
{
  "id": "unique-id",
  "name": "automation-name",
  "type": "skill|hook|subagent|permission|custom-command|claude-md",
  "scope": "global|project",
  "path": "path/to/main/file",
  "created": "ISO-timestamp",
  "modified": "ISO-timestamp",
  "description": "what it does"
}
```

### File markers

Add `created-by: setup-automation` marker to files:

**For Skills/Subagents (markdown frontmatter):**
```yaml
---
name: skill-name
description: ...
created-by: setup-automation
---
```

**For JSON configs (hooks, permissions, custom-commands):**
Add to the specific entry:
```json
{
  "_meta": {
    "createdBy": "setup-automation",
    "createdAt": "ISO-timestamp"
  }
}
```

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
created-by: setup-automation
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
created-by: setup-automation
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

## Step 6: Verify COMPLETENESS

**BEFORE showing results to user, verify ALL planned components were created:**

1. Check your CREATION PLAN from Step 3
2. For each component:
   - [ ] File exists at the specified path
   - [ ] Content is valid (matches schema)
   - [ ] Registered in automations-registry.json

**If ANY component is missing or invalid:**
- DO NOT proceed to Step 7
- GO BACK and create/fix the missing component
- This is NON-NEGOTIABLE

### Verification checklist for combinations:

**Hook + Skill:**
- [ ] Skill file exists and has valid frontmatter
- [ ] Hook script exists and is executable
- [ ] Hook is registered in settings.json with VALID event (PreToolUse, NOT PreCommit)
- [ ] Both are in automations-registry.json with `relatedHook`/`relatedSkill` links

**Skill + Subagent:**
- [ ] Skill file exists
- [ ] Subagent file exists with valid tools/model
- [ ] Both registered with links

**Permissions + CLAUDE.md:**
- [ ] Permission rule in settings.json
- [ ] Explanation in CLAUDE.md
- [ ] Both registered

---

## Step 7: Test the automation

**MANDATORY: Test that the automation actually works before finishing.**

### For Hooks:
```bash
# Test the hook script directly
~/.claude/scripts/your-hook.sh "test command"
echo $?  # Should be 0 (allow) or 2 (block)
```

If the test fails:
1. Fix the script
2. Re-test
3. DO NOT finish until the test passes

### For Skills:
- Verify the skill appears in `/skills` list
- If `disable-model-invocation: false`, verify Claude recognizes when to use it

### For Permissions:
- Verify the rule appears in settings
- Test with a matching command

---

## Step 8: Final report

Only after ALL verifications pass:

1. Show the CREATION PLAN with all boxes checked:
   ```
   CREATION COMPLETE:
   [x] Component 1: Hook - ~/.claude/scripts/check-semver.sh
   [x] Component 2: Skill - ~/.claude/skills/semver/SKILL.md
   ```

2. Show test results:
   ```
   TESTS PASSED:
   [x] Hook blocks when VERSION not staged (exit 2)
   [x] Hook allows when VERSION is staged (exit 0)
   [x] Skill registered and visible
   ```

3. Explain how to use the automation
4. Confirm all components are in the registry

**If you cannot complete all steps, explicitly tell the user what failed and why.**

---

## Important notes

### NEVER do these things:
- ❌ Create a hook with invalid event (PreCommit, PostCommit, PreBash, etc.)
- ❌ Promise "Hook + Skill" but only create the skill
- ❌ Remove a broken component instead of fixing it
- ❌ Skip testing and verification
- ❌ Finish with unchecked items in the CREATION PLAN

### ALWAYS do these things:
- ✅ Validate against schemas BEFORE creating
- ✅ Create ALL components of a combination
- ✅ Test each component works
- ✅ Register everything in automations-registry.json
- ✅ Link related components (relatedHook/relatedSkill)

### Technical notes:
- If the user uses `--dangerously-skip-permissions`, Permissions won't work. Suggest Hook as an alternative for blocks.
- CLAUDE.md instructions are advisory, not guaranteed. If certainty is needed, use Hook.
- Hooks are scripts, they don't have access to Claude's intelligence. For complex logic, combine Hook + Skill.
- Subagents consume extra tokens but preserve the main context.
- Valid hook events: SessionStart, SessionEnd, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Notification, Stop, PreCompact, SubagentStart, SubagentStop
- All automations are tracked in `~/.claude/automations-registry.json` for management with list/edit/delete/export/import.
