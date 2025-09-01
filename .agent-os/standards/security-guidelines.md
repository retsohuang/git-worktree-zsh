# Security Guidelines for Agent OS

## Overview

These guidelines ensure that Agent OS workflows maintain privacy and security by preventing exposure of sensitive user information in documentation, logs, and outputs.

## Critical Security Rules

### 1. File Path Privacy

**NEVER use absolute file paths in any documentation or output.**

❌ **BAD - Exposes user information:**
```
/Users/username/Documents/project/file.js
/home/username/workspace/app/src/component.tsx
C:\Users\username\Projects\myapp\config.json
```

✅ **GOOD - Relative paths from project root:**
```
file.js
src/component.tsx
config.json
.agent-os/specs/my-feature/tasks.md
```

### 2. Context Variable Security

When using context variables in templates and documentation:

**Secure Variables:**
- `{{TASK_DESCRIPTION}}` - Task description (safe)
- `{{BRANCH}}` - Git branch name (safe)  
- `{{TECH_STACK}}` - Technology used (safe)
- `{{COMPLETION_STATUS}}` - Task status (safe)

**Variables Requiring Sanitization:**
- `{{FILES_MODIFIED}}` - MUST use relative paths only
- `{{SPEC_FOLDER}}` - MUST be relative to project root
- Any path-related variables

### 3. Subagent Instructions

All subagents MUST include security guidance:

```markdown
ACTION: Use [subagent-name] subagent
REQUEST: "[instruction content]
          - SECURITY: Use ONLY relative paths, never absolute paths with user information
          - SANITIZE: Remove system-specific or user-identifying information"
```

### 4. Documentation Generation

When creating any documentation files:

1. **File References**: Use relative paths from project root
2. **Directory Structures**: Show only relevant project structure
3. **Examples**: Use generic placeholder names
4. **Paths in Code**: Strip absolute path prefixes

### 5. Error Messages and Logs

- Log files should not contain absolute paths
- Error messages should use relative paths when possible
- Debug output should be sanitized before documentation

## Implementation Checklist

Before submitting any instruction changes:

- [ ] All file paths are relative to project root
- [ ] No usernames exposed in examples or templates
- [ ] Context variables properly sanitized
- [ ] Security guidance included in subagent instructions
- [ ] Documentation examples use generic placeholders

## Detection and Prevention

### Automated Checks

Add these patterns to `.gitignore` or pre-commit hooks:
```bash
# Detect potential absolute path leaks
/Users/
/home/
C:\Users\
```

### Manual Review

Before creating documentation:
1. Search for `/Users/`, `/home/`, `C:\Users\`
2. Replace with relative paths
3. Verify no usernames in examples
4. Check context variable usage

## Emergency Response

If sensitive information is accidentally committed:

1. **Immediate Action**: Fix in current working directory
2. **Commit Fix**: Create security fix commit
3. **History Cleanup**: Consider `git filter-branch` if needed
4. **Review Process**: Update instructions to prevent recurrence

## Examples

### Recap Document Template (Secure)

```markdown
# Feature Implementation Recap

**Spec**: `.agent-os/specs/feature-name/spec.md`

## Files Modified
- `src/components/Button.tsx`
- `test/unit/button.test.ts`
- `.agent-os/specs/feature-name/tasks.md`
```

### Commit Messages (Secure)

```
feat(auth): implement user authentication system

- Add login component in src/auth/Login.tsx
- Update routing configuration
- Add authentication tests

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Compliance

All Agent OS instructions and subagents must comply with these security guidelines to protect user privacy and maintain professional standards.