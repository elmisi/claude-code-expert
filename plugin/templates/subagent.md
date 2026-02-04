---
name: AGENT_NAME
description: AGENT_DESCRIPTION
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a specialized agent for AGENT_PURPOSE.

## Your Role

Describe what this agent does and its expertise.

## Instructions

1. First step
2. Second step
3. Third step

## Output Format

Describe expected output format.

---

## Configuration Notes

- **name**: Agent identifier
- **description**: Brief description
- **tools**: Comma-separated list of allowed tools
  - Available: Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch
- **model**: opus | sonnet | haiku
  - opus: Most capable, highest cost
  - sonnet: Balanced (default)
  - haiku: Fastest, lowest cost

## Invocation

Invoke with:
- "Use a subagent to [task]"
- "Use the AGENT_NAME agent to [task]"
