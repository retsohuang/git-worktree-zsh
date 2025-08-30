---
description: Create a pull request for completed feature implementation
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
allowed-tools: mcp__git__git_status, mcp__git__git_log, mcp__git__git_diff, mcp__filesystem__read_text_file, mcp__filesystem__list_directory, Task, Bash, Glob, Grep
---

# Create Pull Request Command

## Overview

Create a pull request for completed feature implementation after tasks have been executed and committed.

<pre_flight_check>
EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md (use mcp__filesystem__read_text_file)
</pre_flight_check>

<process_flow>

<step number="1" name="branch_status_check">

### Step 1: Branch Status Check

Verify that the current branch has commits ready for PR and determine the target branch.

<status_verification>
<current_branch>
CHECK: Current branch is not main/master
VERIFY: Branch has local commits ahead of main
CONFIRM: All changes are committed (working directory clean)
</current_branch>

<commit_status>
VALIDATE: Working directory is clean
CHECK: Local commits exist and are ready to push
VERIFY: No uncommitted changes exist
</commit_status>

<target_branch>
IDENTIFY: Target branch (usually main or master)
CHECK: Target branch exists and is accessible
CALCULATE: Local commits difference with target branch
</target_branch>
</status_verification>

<error_conditions>

- ON_MAIN_BRANCH: "Cannot create PR from main branch"
- NO_LOCAL_COMMITS: "No local commits to create PR with"
- UNCOMMITTED_CHANGES: "Uncommitted changes detected, commit first"
- WORKING_DIR_DIRTY: "Working directory not clean, commit changes first"
  </error_conditions>

<instructions>
  ACTION: Check current git status and branch state
  VALIDATE: Branch has local commits ready for push and PR
  IDENTIFY: Target branch for PR
  CONFIRM: All prerequisites are met
</instructions>

</step>

<step number="2" subagent="project-manager" name="spec_context_analysis">

### Step 2: Spec Context Analysis

Use project-manager subagent to gather comprehensive context for PR description from spec files and completed tasks.

<branch_to_spec_mapping>
<branch_name_analysis>
PARSE: Current branch name to identify related spec
PATTERN: Extract spec name from branch (remove date prefixes)
EXAMPLE: "git-code-review-command" → "2025-08-14-git-code-review-command"
LOCATE: Corresponding spec folder in .agent-os/specs/
</branch_name_analysis>
</branch_to_spec_mapping>

<context_fetcher_request>
ACTION: Use project-manager subagent
REQUEST: "Gather PR context for branch [CURRENT_BRANCH_NAME]:

            **Required Context:**
            - Spec description from spec.md or spec-lite.md in .agent-os/specs/[SPEC_FOLDER]/
            - Completed tasks summary from .agent-os/specs/[SPEC_FOLDER]/tasks.md
            - Feature objectives and key deliverables

            **Git Context:**
            - Files modified in current branch (compared to main/master)
            - Commit messages from branch history
            - Overall scope of changes

            **Output Format:**
            - Spec Name: [extracted from spec files]
            - Feature Summary: [brief description for PR title]
            - Completed Tasks: [list of completed tasks with descriptions]
            - Key Features: [main features implemented]
            - Modified Files: [list of changed files]
            - Commit Summary: [summary of commit messages]"

PROCESS: Context-fetcher response for PR description generation
VALIDATE: All required information is available
</context_fetcher_request>

<context_requirements>
<essential_context> - Spec name and feature description - List of completed tasks from tasks.md - Key features and deliverables implemented - Files modified in the branch - Commit history summary
</essential_context>

<optional_context> - Testing instructions (if specified in spec) - Breaking changes (if any mentioned) - Dependencies or prerequisites - Technical implementation details
</optional_context>

<fallback_behavior>
IF spec files not found:
USE: Branch name and commit messages for basic context
NOTE: Limited context available, basic PR description will be generated
IF tasks.md not found:
USE: Commit messages to infer completed work
IF no context available:
ERROR: Cannot create meaningful PR description
</fallback_behavior>
</context_requirements>

<instructions>
  ACTION: Use project-manager subagent to gather comprehensive PR context
  REQUEST: Spec files, tasks, and git context for current branch
  PROCESS: Returned context into structured format for PR creation
  VALIDATE: Sufficient context available for meaningful PR description
  FALLBACK: Handle missing files gracefully with reduced context
</instructions>

</step>

<step number="3" subagent="git-workflow" name="push_and_pull_request_creation">

### Step 3: Push and Pull Request Creation

Use git-workflow subagent to push the branch and create the pull request with comprehensive description.

<push_and_pr_request>
ACTION: Use git-workflow subagent
REQUEST: "Push branch and create pull request for completed feature: - Current Branch: [CURRENT_BRANCH_NAME] - Target Branch: [TARGET_BRANCH] (usually main) - Spec: [SPEC_NAME_AND_PATH] - Completed Tasks: [TASK_SUMMARY] - Key Features: [FEATURE_LIST] - Action: PUSH BRANCH then CREATE PULL REQUEST"
WAIT: For push and PR creation completion
CAPTURE: PR URL for user feedback
</push_and_pr_request>

<pr_description_template>

## Summary

[FEATURE_SUMMARY_FROM_SPEC]

## Completed Tasks

- [x] Task 1: [TASK_DESCRIPTION]
- [x] Task 2: [TASK_DESCRIPTION]
- [x] Task N: [TASK_DESCRIPTION]

## Key Features Implemented

1. **[FEATURE_1]** - [DESCRIPTION]
2. **[FEATURE_2]** - [DESCRIPTION]
3. **[FEATURE_N]** - [DESCRIPTION]

## Files Modified

- [LIST_OF_MODIFIED_FILES]

## Testing

[TESTING_INFORMATION_IF_APPLICABLE]

## Breaking Changes

[BREAKING_CHANGES_IF_ANY]

🤖 Generated with [Claude Code](https://claude.ai/code)
</pr_description_template>

<pr_title_format>
PATTERN: "[spec-name]: [brief-feature-description]"
EXAMPLES: - "git-code-review: Implement Git Integration and Analysis Engine" - "user-auth: Add OAuth2 authentication system" - "dashboard: Create responsive dashboard layout"
</pr_title_format>

<instructions>
  ACTION: Use git-workflow subagent to create PR
  FORMAT: Use template for consistent PR descriptions
  INCLUDE: All relevant context and completed tasks
  CAPTURE: PR URL for user confirmation
</instructions>

</step>

<step number="4" name="pr_confirmation">

### Step 4: Pull Request Confirmation

Confirm PR creation and provide user with PR details and next steps.

<confirmation_format>

## 🎉 Pull Request Created Successfully

**PR Title:** [PR_TITLE]

**PR URL:** [GITHUB_PR_URL]

**Branch:** [CURRENT_BRANCH] → [TARGET_BRANCH]

**Spec:** [SPEC_NAME]

## Summary of Changes

- [BRIEF_SUMMARY_OF_IMPLEMENTED_FEATURES]

## Next Steps

1. **Review:** The PR is ready for code review
2. **Testing:** Run any additional tests if needed
3. **Merge:** Merge the PR when approved

You can view and manage the PR at: [GITHUB_PR_URL]
</confirmation_format>

<success_criteria>

- PR created successfully
- PR URL captured and provided to user
- PR description includes all relevant context
- User can access and manage the PR
  </success_criteria>

<instructions>
  ACTION: Confirm successful PR creation
  PROVIDE: Complete PR details to user
  INCLUDE: PR URL and next steps
  FORMAT: Clear, actionable information
</instructions>

</step>

</process_flow>

## Error Handling

<error_scenarios>
<git_errors> - Branch not found or inaccessible - Remote repository connection issues - Authentication or permission problems - Merge conflicts with target branch
</git_errors>

<context_errors> - Spec folder not found - Tasks.md file missing or unreadable - Invalid branch name format - No completed tasks to summarize
</context_errors>

<pr_creation_errors> - PR already exists for branch - Target branch doesn't exist - GitHub API authentication issues - Repository access restrictions
</pr_creation_errors>
</error_scenarios>

<error_responses>
<user_friendly_messages>
❌ **Pull Request Creation Error**

      **Issue:** [CLEAR_DESCRIPTION]

      **Suggestion:** [ACTIONABLE_FIX]

      **Need Help?** Try:
      - Check if you're on the correct branch
      - Verify all changes are committed and pushed
      - Ensure target branch exists and is accessible

</user_friendly_messages>
</error_responses>
