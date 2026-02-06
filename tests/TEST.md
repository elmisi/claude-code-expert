# Test Cases for claude-code-automation

This document describes all test scenarios for the `automate` skill.

## Test Categories

1. **Single Automation Types** - One automation mechanism
2. **Combinations** - Multiple mechanisms working together
3. **Scope Variations** - Global vs project-specific
4. **Edge Cases** - Special scenarios

---

## 1. Single Automation Types

### TEST-01: Hook Only
**Scenario:** Block all git push commands
**Input:** `/automate block git push without authorization`
**Interview Answers:**
- Timing: Always, on every action
- Guaranteed: Yes, MUST happen
- Intelligence needed: No, script only
- Scope: All projects

**Expected Output:**
- File: `~/.claude/settings.json`
- Content: Hook in `PreToolUse` with `Bash` matcher that blocks `git push`

**Verification:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'git push'; then echo 'Push blocked' >&2; exit 2; fi"
      }]
    }]
  }
}
```

---

### TEST-02: Skill (Automatic)
**Scenario:** API naming conventions applied automatically
**Input:** `/automate REST API naming conventions`
**Interview Answers:**
- Timing: Only in certain contexts (when working on API code)
- Guaranteed: No, guideline
- Intelligence needed: Yes, Claude decides
- Scope: This project only

**Expected Output:**
- File: `.claude/skills/api-conventions/SKILL.md`
- Frontmatter: `disable-model-invocation: false`

**Verification:**
```markdown
---
name: api-conventions
description: REST API naming conventions
disable-model-invocation: false
---
```

---

### TEST-03: Skill (Manual Workflow)
**Scenario:** Security review workflow invoked on demand
**Input:** `/automate security code review`
**Interview Answers:**
- Timing: Only on explicit user request
- Guaranteed: No, guideline
- Intelligence needed: Yes, Claude analyzes
- Scope: All projects

**Expected Output:**
- File: `~/.claude/skills/security-review/SKILL.md`
- Frontmatter: `disable-model-invocation: true`

**Verification:**
```markdown
---
name: security-review
description: Security code review workflow
disable-model-invocation: true
---
```

---

### TEST-04: Subagent
**Scenario:** Independent code review with clean context
**Input:** `/automate independent code review for PRs`
**Interview Answers:**
- Timing: Only on explicit user request
- Guaranteed: No
- Intelligence needed: Yes
- Needs separate context: Yes, unbiased review
- Scope: All projects

**Expected Output:**
- File: `~/.claude/agents/code-reviewer.md`
- Contains: tools list, model specification

**Verification:**
```markdown
---
name: code-reviewer
description: Independent code review with clean context
tools: Read, Grep, Glob, Bash
model: sonnet
---
```

---

### TEST-05: Permissions
**Scenario:** Allow commit but deny push
**Input:** `/automate allow commit but require approval for push`
**Interview Answers:**
- Timing: Always
- Guaranteed: Yes
- Uses --dangerously-skip-permissions: No
- Scope: All projects

**Expected Output:**
- File: `~/.claude/settings.json`
- Content: permissions block

**Verification:**
```json
{
  "permissions": {
    "allow": ["Bash(git commit *)"],
    "deny": ["Bash(git push *)"]
  }
}
```

---

### TEST-06: CLAUDE.md Rule
**Scenario:** Simple reminder to run tests before commit
**Input:** `/automate remind to run tests before commit`
**Interview Answers:**
- Timing: Always (but advisory)
- Guaranteed: No, just a reminder
- Intelligence needed: No
- Scope: This project only

**Expected Output:**
- File: `./CLAUDE.md` (project root)
- Content: Rule about running tests

**Verification:**
```markdown
## Testing
Before committing, run tests to ensure nothing is broken.
```

---

### TEST-07: Custom Command
**Scenario:** Shortcut for running lint and fix
**Input:** `/automate shortcut for lint and fix`
**Interview Answers:**
- Timing: Only on explicit request
- Guaranteed: N/A
- Parameters needed: No
- Scope: This project

**Expected Output:**
- File: `.claude/settings.json`
- Content: customCommands entry

**Verification:**
```json
{
  "customCommands": {
    "lint": "Run linter and fix all issues automatically"
  }
}
```

---

## 2. Combinations

### TEST-08: Hook + Skill
**Scenario:** Semantic versioning on every commit (guaranteed + intelligent)
**Input:** `/automate semantic versioning on every commit`
**Interview Answers:**
- Timing: Always, every commit
- Guaranteed: Yes, MUST happen
- Intelligence needed: Yes, Claude decides patch/minor/major
- Scope: Projects with VERSION file (opt-in)

**Expected Output:**
- File 1: `~/.claude/settings.json` (hook)
- File 2: `~/.claude/skills/semver/SKILL.md` (logic)
- File 3: `~/.claude/CLAUDE.md` (rule)

**Verification:**
- Hook triggers before commit
- Skill contains versioning rules
- CLAUDE.md explains opt-in behavior

---

### TEST-09: Hook + CLAUDE.md
**Scenario:** Block writes to migrations folder with explanation
**Input:** `/automate protect migrations folder from accidental changes`
**Interview Answers:**
- Timing: Always
- Guaranteed: Yes, MUST block
- Intelligence needed: No
- Needs explanation: Yes
- Scope: This project

**Expected Output:**
- File 1: `.claude/settings.json` (hook blocks)
- File 2: `./CLAUDE.md` (explains why)

**Verification:**
- Hook in `PreToolUse` with `Edit|Write` matcher blocks paths containing `migrations/`
- CLAUDE.md explains migration policy

---

### TEST-10: Skill + Subagent
**Scenario:** Refactoring workflow with deep analysis
**Input:** `/automate refactoring workflow with impact analysis`
**Interview Answers:**
- Timing: Only on explicit request
- Guaranteed: No
- Intelligence needed: Yes
- Needs deep analysis: Yes, check all usages
- Scope: All projects

**Expected Output:**
- File 1: `~/.claude/skills/refactor/SKILL.md` (workflow)
- File 2: `~/.claude/agents/impact-analyzer.md` (deep analysis)

**Verification:**
- Skill defines refactoring steps
- Skill invokes subagent for impact analysis
- Subagent has Read, Grep, Glob tools

---

### TEST-11: Permissions + CLAUDE.md
**Scenario:** Block dangerous commands with explanation
**Input:** `/automate block rm -rf and explain why`
**Interview Answers:**
- Timing: Always
- Guaranteed: Yes
- Uses --dangerously-skip-permissions: No
- Needs explanation: Yes
- Scope: All projects

**Expected Output:**
- File 1: `~/.claude/settings.json` (permissions deny)
- File 2: `~/.claude/CLAUDE.md` (explanation)

**Verification:**
```json
{
  "permissions": {
    "deny": ["Bash(rm -rf *)"]
  }
}
```

---

### TEST-12: Permissions + Hook (for skip-permissions users)
**Scenario:** Block dangerous commands even with --dangerously-skip-permissions
**Input:** `/automate block rm -rf even in skip-permissions mode`
**Interview Answers:**
- Timing: Always
- Guaranteed: Yes
- Uses --dangerously-skip-permissions: Yes
- Scope: All projects

**Expected Output:**
- File: `~/.claude/settings.json` (hook, NOT permissions)
- Note: Permissions won't work, use hook instead

**Verification:**
- Should create Hook, not Permissions
- Should warn user about skip-permissions limitation

---

## 3. Scope Variations

### TEST-13: Global Scope
**Scenario:** Rule applies to all projects
**Input:** `/automate always use conventional commits`
**Interview Answers:**
- Scope: All projects

**Expected Output:**
- Files in: `~/.claude/` (global)

**Verification:**
- No files in project `.claude/`
- Files in home `~/.claude/`

---

### TEST-14: Project Scope
**Scenario:** Rule applies only to current project
**Input:** `/automate use tabs for indentation`
**Interview Answers:**
- Scope: This project only

**Expected Output:**
- Files in: `./.claude/` or `./CLAUDE.md` (project)

**Verification:**
- Files in project directory
- No files in home `~/.claude/`

---

### TEST-15: Opt-in Pattern
**Scenario:** Automation activates only if marker file exists
**Input:** `/automate auto-format on save but only if enabled`
**Interview Answers:**
- Timing: Always (when enabled)
- Opt-in: Yes, need marker file
- Scope: Per-project opt-in

**Expected Output:**
- Skill/Hook checks for marker file (e.g., `.autoformat`)
- Only runs if marker exists

**Verification:**
- Contains check: `test -f .autoformat`
- Skips if file doesn't exist

---

## 4. Edge Cases

### TEST-16: Empty/Invalid Input
**Scenario:** User provides vague input
**Input:** `/automate make things better`

**Expected Behavior:**
- Should ask clarifying questions
- Should NOT create files without understanding intent

**Verification:**
- AskUserQuestion is invoked
- No files created prematurely

---

### TEST-17: Conflicting Requirements
**Scenario:** User wants guaranteed execution without hooks
**Input:** `/automate always run tests but don't use hooks`
**Interview Answers:**
- Timing: Always
- Guaranteed: Yes
- Can use hooks: No

**Expected Behavior:**
- Explain limitation: can't guarantee without hooks
- Suggest alternatives
- Ask user to reconsider

**Verification:**
- Warning about limitation is shown
- User is asked to choose

---

### TEST-18: Existing Automation Detection (Future)
**Scenario:** Automation with same name already exists
**Input:** `/automate semver` (when semver already exists)

**Expected Behavior:**
- Detect existing automation
- Offer options: view, modify, replace, cancel

**Verification:**
- Lists existing files
- Does NOT overwrite without confirmation

---

## Test Execution Checklist

### Manual Testing (Type 1)
- [ ] TEST-01: Hook Only
- [ ] TEST-02: Skill (Automatic)
- [ ] TEST-03: Skill (Manual)
- [ ] TEST-04: Subagent
- [ ] TEST-05: Permissions
- [ ] TEST-06: CLAUDE.md Rule
- [ ] TEST-07: Custom Command
- [ ] TEST-08: Hook + Skill
- [ ] TEST-09: Hook + CLAUDE.md
- [ ] TEST-10: Skill + Subagent
- [ ] TEST-11: Permissions + CLAUDE.md
- [ ] TEST-12: Permissions + Hook
- [ ] TEST-13: Global Scope
- [ ] TEST-14: Project Scope
- [ ] TEST-15: Opt-in Pattern
- [ ] TEST-16: Empty/Invalid Input
- [ ] TEST-17: Conflicting Requirements
- [ ] TEST-18: Existing Automation Detection

### Automated Testing (Type 2)
Scripts in `tests/scripts/` will automate verification of:
- File creation in correct location
- File content matches expected structure
- JSON/YAML syntax validity
