---
description: Create a git commit for completed work
alwaysApply: false
version: 1.0
encoding: UTF-8
allowed-tools: mcp__git__git_status, mcp__git__git_diff_staged, mcp__git__git_diff_unstaged, mcp__git__git_commit, mcp__filesystem__read_text_file, mcp__filesystem__list_directory, Task, Bash, Glob, Grep
---

# Commit Command

## Overview

Create a git commit for completed work with descriptive commit message based on current changes and context.

<pre_flight_check>
EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md (use mcp__filesystem__read_text_file)
</pre_flight_check>

<process_flow>

<step number="1" name="working_directory_status">

### Step 1: Working Directory Status Check

Verify that there are changes ready to commit and assess the scope of modifications.

<status_verification>
<git_status_check>
USE: mcp**git**git_status to check repository state
IDENTIFY: Modified, added, deleted, and untracked files
DETECT: Staged vs unstaged changes
VALIDATE: Repository is in committable state
CHECK: Not in merge, rebase, cherry-pick, or bisect state
</git_status_check>

<staged_changes_analysis>
USE: mcp**git**git_diff_staged to analyze staged changes
EXTRACT: Files and modifications ready for commit
CATEGORIZE: Types of staged changes (code, tests, docs, config)
ASSESS: Scope and impact of staged modifications
</staged_changes_analysis>

<unstaged_changes_analysis>
USE: mcp**git**git_diff_unstaged to analyze unstaged changes
IDENTIFY: Working directory modifications not yet staged
COMPARE: Staged vs unstaged changes for staging decision
DETERMINE: Whether to auto-stage unstaged changes
</unstaged_changes_analysis>

<staging_logic>
IF staged changes exist:
USE: Only staged changes for commit
NOTE: Unstaged changes will remain in working directory
CONFIRM: Commit will include staged changes only
ELSE IF unstaged changes exist:
USE: mcp**git**git_add to stage all unstaged changes
TARGET: All modified, added, and deleted files
CONFIRM: All modifications will be included in commit
ELSE:
ERROR: Nothing to commit, working tree clean
</staging_logic>
</status_verification>

<error_conditions>

- NO_CHANGES: "No changes to commit, working directory is clean"
- MERGE_IN_PROGRESS: "Cannot commit during merge, resolve conflicts first"
- REBASE_IN_PROGRESS: "Cannot commit during rebase, complete rebase first"
- DETACHED_HEAD: "Warning: committing in detached HEAD state"
  </error_conditions>

<mcp_tools_sequence>
STEP_1: Use mcp**git**git_status to get repository state
STEP_2: Use mcp**git**git_diff_staged to analyze staged changes
STEP_3: Use mcp**git**git_diff_unstaged to analyze unstaged changes
STEP_4: Use mcp**git**git_add if staging is needed
FALLBACK: Use Bash tool if MCP tools fail
</mcp_tools_sequence>

<instructions>
  ACTION: Use MCP git tools to check status and analyze changes
  VALIDATE: Changes are ready for commit using mcp__git__git_status
  ANALYZE: Both staged and unstaged changes with diff tools
  STAGE: Unstaged changes using mcp__git__git_add if needed
  ASSESS: Scope and type of changes for commit message generation
</instructions>

</step>

<step number="2" subagent="context-fetcher" name="commit_context_analysis">

### Step 2: Commit Context Analysis

Use context-fetcher subagent to gather context for generating an appropriate commit message.

<context_gathering_request>
ACTION: Use context-fetcher subagent
REQUEST: "Analyze current changes for commit message generation:

            **Git Context (from MCP tools):**
            - Repository status from mcp__git__git_status
            - Staged changes diff from mcp__git__git_diff_staged
            - Unstaged changes diff from mcp__git__git_diff_unstaged
            - Current branch information
            - Files modified, added, deleted in current changes
            - Overall scope of modifications for commit

            **Spec Context (if applicable):**
            - Current spec being worked on (from branch name or recent work)
            - Related tasks or features being implemented
            - Overall objective of current development work

            **Change Categorization:**
            - Primary change type: feature, bugfix, refactor, docs, test, config
            - Affected components or areas of codebase
            - Breaking changes or notable modifications

            **Output Format:**
            - Change Type: [feature/fix/refactor/docs/test/config/etc.]
            - Scope: [component/area affected]
            - Summary: [brief description of what was done]
            - Details: [additional context if significant changes]
            - Files: [key files modified]"

PROCESS: Context for commit message generation
VALIDATE: Sufficient information for meaningful commit message
</context_gathering_request>

<context_analysis>
  <change_categorization>
    FEATURE: New functionality or capabilities added
    BUGFIX: Problem resolution or error correction
    REFACTOR: Code structure improvements without behavior change
    DOCS: Documentation updates or additions
    TEST: Test additions, modifications, or improvements
    CONFIG: Configuration, build, or tooling changes
    STYLE: Code formatting or style-only changes
  </change_categorization>

  <scope_identification>
    COMPONENT: Specific component, module, or feature affected
    AREA: Broader area of codebase (frontend, backend, api, etc.)
    GLOBAL: Repository-wide or cross-cutting changes
  </scope_identification>

  <commit_significance>
    MAJOR: Significant new features or breaking changes
    MINOR: Small improvements or non-breaking additions
    PATCH: Bug fixes or minor modifications
    TRIVIAL: Formatting, typos, or very small changes
  </commit_significance>
</context_analysis>

<instructions>
  ACTION: Use context-fetcher to analyze current changes
  GATHER: Context about modifications and their purpose
  CATEGORIZE: Type and scope of changes
  PREPARE: Information for commit message generation
</instructions>

</step>

<step number="3" subagent="git-workflow" name="commit_creation">

### Step 3: Commit Creation

Use git-workflow subagent to create the commit with an appropriate message based on the analyzed context.

<commit_creation_process>
  <bash_approach>
    PREFERRED: Use Bash tool for git commit creation
    USE: Bash tool with git commit command
    ADVANTAGE: Better commit message formatting and readability
    FORMAT: Use HEREDOC for proper multiline commit messages
  </bash_approach>

  <fallback_approach>
    IF_BASH_FAILS: Use git-workflow subagent as fallback
    REASON: Ensure commit always succeeds
    MAINTAIN: Same message format and conventions
  </fallback_approach>
</commit_creation_process>

<bash_commit_request>
  ACTION: Use Bash tool with git commit command
  MESSAGE: Generate commit message based on context analysis: - Type: [CHANGE_TYPE from context analysis] - Scope: [SCOPE from context analysis] - Description: [SUMMARY from context analysis] - Body: [DETAILED_CONTEXT if significant changes] - Footer: ALWAYS include Claude attribution footer

  FORMAT: Follow conventional commit standards: - "type(scope): description" for subject - Optional body for complex changes - Reference specs/tasks if applicable - MANDATORY Claude footer at end

  VALIDATE: Commit message follows guidelines: - Max 50 chars for subject line - Imperative mood ("add" not "added") - Lowercase after type/scope - No trailing period in subject - Claude footer included

  HEREDOC_FORMAT: Use HEREDOC for proper multiline formatting:
  ```bash
  git commit -m "$(cat <<'EOF'
  [SUBJECT_LINE]

  [COMMIT_BODY if applicable]

  🤖 Generated with [Claude Code](https://claude.ai/code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  EOF
  )"
  ```

  CONFIRM: Commit created with appropriate hash
</bash_commit_request>

<git_workflow_fallback>
IF Bash git commit fails:
ACTION: Use git-workflow subagent as fallback
REQUEST: "Create git commit with contextual message:

              **Change Analysis:**
              - Type: [CHANGE_TYPE from context analysis]
              - Scope: [SCOPE from context analysis]
              - Summary: [SUMMARY from context analysis]
              - Files: [KEY_FILES from context analysis]

              **Commit Instructions:**
              - Create commit with generated message
              - Follow conventional commit format
              - Include relevant details in commit body if significant
              - MANDATORY: Include Claude attribution footer
              - Action: COMMIT ONLY, do not push"

    WAIT: For commit completion
    CONFIRM: Commit created successfully with appropriate message

</git_workflow_fallback>

<commit_message_guidelines>
  <conventional_commits>
    FORMAT: "type(scope): description"
    EXAMPLES: - "feat(auth): add OAuth2 authentication system" - "fix(api): resolve user validation error" - "refactor(components): reorganize button component structure" - "docs(readme): update installation instructions" - "test(integration): add comprehensive API testing"
  </conventional_commits>

  <subject_line_rules>
    LENGTH: Maximum 50 characters for subject line
    STYLE: Imperative mood ("add" not "added" or "adds")
    CAPITALIZATION: Lowercase after type/scope prefix
    PUNCTUATION: No trailing period
  </subject_line_rules>

  <commit_body>
    WHEN_TO_INCLUDE: Complex changes, breaking changes, or important context
    FORMAT: Wrap at 72 characters, separate from subject with blank line
    CONTENT: Why the change was made, not just what changed
    REFERENCES: Include spec, task, or issue references if applicable
  </commit_body>

  <claude_footer>
    ALWAYS_INCLUDE: Claude attribution footer for all commits
    FORMAT: Always end commit messages with:

    🤖 Generated with [Claude Code](https://claude.ai/code)

    Co-Authored-By: Claude <noreply@anthropic.com>
  </claude_footer>
</commit_message_guidelines>

<tools_sequence>
STEP_1: Use mcp**git**git_add if additional staging needed
STEP_2: Use Bash tool with git commit HEREDOC format
STEP_3: Capture commit hash from successful commit
FALLBACK: Use git-workflow subagent if Bash fails
</tools_sequence>

<instructions>
  ACTION: Use Bash tool with git commit HEREDOC format for commit creation
  FALLBACK: Use git-workflow subagent if Bash fails
  APPLY: Commit message guidelines and conventional commit standards
  INCLUDE: Context from analysis in appropriate message format
  CONFIRM: Commit created with meaningful, descriptive message and hash
  VALIDATE: Commit follows all established conventions
  FORMAT: Use HEREDOC for proper multiline commit message formatting
</instructions>

</step>

<step number="4" name="commit_confirmation">

### Step 4: Commit Confirmation

Confirm commit creation and provide user with commit details and next steps.

<confirmation_format>

## ✅ Commit Created Successfully

**Commit Hash:** [COMMIT_SHA]

**Commit Message:**

```
[COMMIT_MESSAGE_SUBJECT]

[COMMIT_MESSAGE_BODY if applicable]
```

**Files Committed:**

- [LIST_OF_COMMITTED_FILES]

**Changes Summary:**

- [BRIEF_SUMMARY_OF_CHANGES]

## Next Steps

**Local Development:** Continue making changes and commit again as needed

**Push Changes:** Run `/create-pr` to push changes and create pull request when ready

**Additional Commits:** Make more commits on this branch before pushing if needed
</confirmation_format>

<success_criteria>

- Commit created successfully with appropriate message
- All intended changes included in commit
- Commit hash captured and provided to user
- Clear next steps provided
  </success_criteria>

<instructions>
  ACTION: Confirm successful commit creation
  PROVIDE: Complete commit details to user
  INCLUDE: Commit hash, message, and affected files
  SUGGEST: Appropriate next steps for continued development
</instructions>

</step>

</process_flow>

## Error Handling

<error_scenarios>
<git_errors> - Repository not in git directory - Working directory conflicts or issues - Git configuration problems - Permissions or access issues
</git_errors>

<staging_errors> - Files cannot be staged due to conflicts - Binary files or large files issues - Ignored files attempted to be committed - Index corruption or issues
</staging_errors>

<commit_errors> - Commit hooks preventing commit - Pre-commit validation failures - Disk space or system resource issues - Git object database problems
</commit_errors>
</error_scenarios>

<error_responses>
<user_friendly_messages>
❌ **Commit Creation Error**

    **Issue:** [CLEAR_DESCRIPTION]

    **Suggestion:** [ACTIONABLE_FIX]

    **Need Help?** Try:
    - Check git status to see current repository state
    - Resolve any merge conflicts or git issues
    - Verify you're in a git repository
    - Check if pre-commit hooks are blocking the commit

</user_friendly_messages>
</error_responses>
