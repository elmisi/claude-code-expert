---
name: SKILL_NAME
description: SKILL_DESCRIPTION
disable-model-invocation: true
---

# SKILL_NAME

The user wants to: $ARGUMENTS

---

## Step 1: Understand the request

Analyze what the user is asking for.

## Step 2: Gather information

Use Read, Grep, Glob to understand the codebase context.

## Step 3: Execute

Perform the requested task.

## Step 4: Verify

Confirm the task was completed successfully.

---

## Notes

- Replace SKILL_NAME with your skill identifier (used for /skill-name invocation)
- Replace SKILL_DESCRIPTION with what the skill does
- Set disable-model-invocation to:
  - `true`: Only invoked manually via /skill-name
  - `false`: Claude may apply automatically when relevant
- $ARGUMENTS is replaced with user input after /skill-name
