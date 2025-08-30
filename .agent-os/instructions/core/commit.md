---
description: Create a git commit for completed work
alwaysApply: false
version: 2.0
encoding: UTF-8
allowed-tools: mcp__git__git_status, mcp__git__git_diff_staged, mcp__git__git_diff_unstaged, Task, Bash
---

# Commit Command

## Overview

Create a git commit for completed work with descriptive commit message based on current changes and context.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md (use mcp__filesystem__read_text_file)
</pre_flight_check>

<process_flow>

<step number="1" name="status_check">

### Step 1: Repository Status Check

Verify there are changes to commit using MCP git tools.

<status_verification>
USE: mcp__git__git_status to check repository state
IDENTIFY: Modified, added, deleted, and untracked files
DETECT: Staged vs unstaged changes
VALIDATE: Repository is in committable state
ERROR_IF: No changes to commit, merge/rebase in progress
</status_verification>

<instructions>
  ACTION: Use mcp__git__git_status to verify changes exist
  VALIDATE: Repository is ready for commit
  ERROR: If no changes or git conflicts exist
</instructions>

</step>

<step number="2" subagent="git-workflow" name="commit_creation">

### Step 2: Create Commit

Use git-workflow subagent to analyze changes and create commit with proper message.

<commit_request>
ACTION: Use git-workflow subagent
REQUEST: "Create git commit for current changes:

**Requirements:**
- Analyze all staged and unstaged changes using MCP git tools
- Stage unstaged changes if no staged changes exist
- Generate conventional commit message (type(scope): description)
- Include commit body for significant changes
- MANDATORY: Include Claude attribution footer:
  
  🤖 Generated with [Claude Code](https://claude.ai/code)
  
  Co-Authored-By: Claude <noreply@anthropic.com>

**Process:**
1. Check git status and analyze changes
2. Stage changes if needed (git add)
3. Generate appropriate commit message following conventions
4. Create single commit with descriptive message
5. Return commit hash and summary

**Commit Message Guidelines:**
- Subject: max 50 chars, imperative mood, no trailing period
- Body: wrap at 72 chars, explain why not what
- Footer: always include Claude attribution
- Format: type(scope): description

**Change Types:**
- feat: new functionality
- fix: bug fixes  
- refactor: code restructuring
- docs: documentation changes
- test: test additions/changes
- config: configuration/tooling changes

IMPORTANT: Create only ONE commit, do not duplicate commits."

WAIT: For commit completion with hash
CONFIRM: Single commit created successfully
</commit_request>

<instructions>
  ACTION: Use git-workflow subagent to handle entire commit process
  DELEGATE: Status checking, staging, message generation, and commit creation
  ENSURE: Only one commit is created
  CAPTURE: Commit hash and details for confirmation
</instructions>

</step>

<step number="3" name="confirmation">

### Step 3: Commit Confirmation

Confirm successful commit creation and provide next steps.

<confirmation_format>
## ✅ Commit Created Successfully

**Commit Hash:** [COMMIT_SHA]

**Files Committed:** [LIST_OF_FILES]

**Changes Summary:** [BRIEF_DESCRIPTION]

## Next Steps

- **Continue Development:** Make more commits as needed
- **Create PR:** Run `/create-pr` when ready to push and create pull request
- **Local Testing:** Test changes before pushing
</confirmation_format>

<instructions>
ACTION: Confirm commit creation with hash and file list
PROVIDE: Clear next steps for user
SUGGEST: Appropriate workflow continuation
</instructions>

</step>

</process_flow>

## Error Handling

<error_scenarios>
- NO_CHANGES: "No changes to commit, working directory is clean"
- GIT_CONFLICTS: "Cannot commit during merge/rebase, resolve conflicts first" 
- PERMISSIONS: "Git permissions or configuration issues"
- SUBAGENT_FAILURE: "Git-workflow subagent encountered an error"
</error_scenarios>

<error_responses>
❌ **Commit Creation Failed**

**Issue:** [CLEAR_DESCRIPTION]

**Solution:** [ACTIONABLE_FIX]

**Try:**
- Check `git status` for repository state
- Resolve any merge conflicts
- Verify git configuration
- Ensure you're in a git repository
</error_responses>