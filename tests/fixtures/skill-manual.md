---
name: security-review
description: Security code review workflow
disable-model-invocation: true
---

# Security Review Workflow

Invoke with: `/security-review` or `use the security-review skill`

## Checklist

### 1. Input Validation
- [ ] All user inputs are validated
- [ ] SQL queries use parameterized statements
- [ ] No direct string concatenation in queries

### 2. Authentication & Authorization
- [ ] Authentication is required for protected routes
- [ ] Authorization checks are in place
- [ ] Tokens are validated properly

### 3. Data Exposure
- [ ] Sensitive data is not logged
- [ ] API responses don't leak internal details
- [ ] Error messages are generic for users

### 4. Dependencies
- [ ] No known vulnerabilities in dependencies
- [ ] Dependencies are up to date
- [ ] Lock file is committed

### 5. Secrets
- [ ] No hardcoded secrets
- [ ] Environment variables are used
- [ ] .env files are gitignored

## Report Format

After review, provide:
1. Summary of findings
2. Risk level (Critical/High/Medium/Low)
3. Specific line references
4. Recommended fixes
