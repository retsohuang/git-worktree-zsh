---
description: Fix GitHub pull request comments by analyzing feedback and implementing changes
alwaysApply: false
version: 1.0
encoding: UTF-8
allowed-tools: mcp__filesystem__read_text_file, mcp__filesystem__list_directory, mcp__filesystem__search_files, Task, Bash, Glob, Grep, Read, Edit, MultiEdit, Write, mcp__git__git_status
---

# Fix PR Comment Command

## Overview

Analyze GitHub pull request comments using `gh pr view --comments` command, implement clear improvements automatically, then present questionable fixes to user for confirmation at the end.

<pre_flight_check>
  USE: mcp__filesystem__read_text_file to read @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" name="fetch_pr_comments">

### Step 1: Fetch PR Comments

Use the GitHub CLI `gh pr view --comments` command to retrieve all comments from the current pull request.

<pr_comments_execution>
  ACTION: Execute `gh pr view --comments` command via Bash tool
  PURPOSE: Retrieve all comments and feedback from the pull request
  CAPTURE: Comment content, authors, timestamps, and context
  PROCESS: Parse comments for actionable feedback
</pr_comments_execution>

<comment_types>
  <actionable_feedback>
    - Code quality improvements
    - Bug reports and fixes needed
    - Security vulnerabilities
    - Performance optimizations
    - Style and formatting issues
    - Missing functionality requests
    - Test coverage suggestions
  </actionable_feedback>

  <non_actionable_feedback>
    - General approval comments
    - Questions already answered
    - Outdated feedback on changed code
    - Subjective preferences without clear benefit
    - Comments requesting clarification only
  </non_actionable_feedback>
</comment_types>

<instructions>
  ACTION: Run `gh pr view --comments` command via Bash to fetch all PR feedback
  PARSE: Comments for actionable vs non-actionable feedback
  CATEGORIZE: Types of changes needed
  PREPARE: List of potential fixes for analysis
</instructions>

</step>

<step number="2" name="initial_comment_analysis">

### Step 2: Initial Comment Analysis

Parse PR comments to identify which files and code sections need examination.

<initial_parsing>
  ACTION: Parse PR comments to extract:
  - Files mentioned in comments
  - Specific line numbers or code sections
  - Type of issues reported (logic, style, performance, etc.)
  - Suggested changes or fixes
  
  IDENTIFY: Which code areas need detailed review
  PREPARE: List of files and sections to examine in Step 3
</initial_parsing>

</step>

<step number="3" name="code_review_and_logic_analysis">

### Step 3: Code Review and Logic Analysis

Thoroughly examine the specific code mentioned in PR comments to understand current implementation.

<detailed_code_review>
  FOR each file/section mentioned in PR comments:
    
    STEP_3A: Read Current Implementation
    ACTION: Use Read tool to examine the specific code
    FOCUS: Understand the logic, purpose, and context
    ANALYZE: How the current implementation works
    TRACE: Step through the logic with different scenarios
    
    STEP_3B: Logic Verification
    VERIFY: Boolean logic, conditional statements, loops
    CHECK: Off-by-one errors, boundary conditions
    ANALYZE: Operator precedence and logical combinations
    TEST: Mental execution with edge cases
    IDENTIFY: Potential issues or correct behavior
    
    STEP_3C: Comment Evaluation Against Code
    MATCH: PR comment to specific code location
    UNDERSTAND: What the comment is suggesting
    EVALUATE: Whether suggestion addresses real issue
    DETERMINE: If current code has logical errors
    COMPARE: Current vs suggested implementation
    
  END FOR
</detailed_code_review>

</step>

<step number="4" subagent="project-manager" name="comment_analysis_and_prioritization">

### Step 4: Comment Analysis and Prioritization (After Code Review)

Use project-manager subagent to analyze comments with full understanding of the code.

<analysis_request>
  ACTION: Use project-manager subagent
  REQUEST: "Analyze PR comments for actionable feedback AFTER having thoroughly reviewed the actual code implementation:

  **Input Data:**
  - All PR comments from `gh pr view --comments` command
  - DETAILED understanding of current code implementation (from Step 3)
  - Specific analysis of logical correctness for each commented section
  - Edge cases and scenarios tested mentally
  - Current codebase context and recent changes
  - Repository structure and coding standards

  **Analysis Tasks:**
  1. **Categorize Comments:**
    - Actionable: Requires code changes
    - Informational: No action needed
    - Questions: Need clarification only
    - Outdated: Already addressed

  2. **Prioritize Actionable Comments:**
    - Critical: Security, bugs, breaking issues
    - Important: Performance, code quality
    - Minor: Style, formatting, suggestions

  3. **Assess Implementation Feasibility:**
    - Easy: Simple changes, low risk
    - Medium: Moderate complexity, some risk
    - Complex: Significant changes, high risk

  4. **Critical Logic Evaluation:**
    - TRACE THROUGH the current logic step by step
    - IDENTIFY all possible execution paths and outcomes
    - TEST the logic with different input scenarios mentally
    - COMPARE current behavior with suggested changes
    - DETERMINE if suggestions actually fix real issues or introduce problems
    - VERIFY logical correctness of both current and suggested approaches
    - Is current code best-in-class?
    - Would suggested changes improve quality?
    - Are there better alternatives to suggested fixes?

  **Output Requirements:**
  - CLEAR_FIXES: Comments that identify genuine logical errors or clear improvements
  - QUESTIONABLE_FIXES: Comments where current implementation may be better or equivalent
  - Implementation difficulty assessment for each category
  - Clear reasoning based on actual code analysis
  - Recommendation: AUTO_FIX or CONFIRM_NEEDED for each comment"

  WAIT: For detailed comment analysis
  PROCESS: Recommendations for fixes
</analysis_request>

<analysis_criteria>
  <code_quality_assessment>
    EVALUATE: Current implementation quality
    CONSIDER: Industry best practices
    ASSESS: Performance implications
    REVIEW: Security considerations
    CHECK: Maintainability impact
  </code_quality_assessment>

  <fix_recommendation>
    AUTO_FIX: When suggestion clearly improves quality
    CONFIRM_NEEDED: When current approach may be better or equal
    SKIP: When comment is not actionable
    PROVIDE_REASONING: For each classification
    SEPARATE_CLEARLY: Auto-fix from confirm-needed comments
  </fix_recommendation>
</analysis_criteria>

<critical_analysis_requirements>
  MANDATORY BEFORE CLASSIFICATION:
  
  LOGIC_VERIFICATION_EXAMPLES:
  - For boolean expressions: Test with actual values (e.g., if condition is "!A && B", test with A=true,B=true; A=false,B=true; etc.)
  - For loops: Check start/end conditions, increment/decrement logic
  - For array/string operations: Verify bounds checking
  - For mathematical operations: Check for overflow, division by zero
  
  COMMENT_EVALUATION_CRITERIA:
  - Does the comment identify a REAL logical error? (Provide proof with examples)
  - Does the comment suggest fixing something that isn't broken?
  - Would the suggested change introduce new bugs or break edge cases?
  - Is the current implementation intentionally designed this way for a reason?
  
  NEVER SKIP:
  - Reading and understanding the actual code before making recommendations
  - Testing logical expressions with concrete examples
  - Considering edge cases and boundary conditions
  - Verifying that suggested changes actually improve the code
</critical_analysis_requirements>

<instructions>
  ACTION: FIRST complete thorough code review and logic analysis (Steps 2-3)
  THEN use project-manager subagent for comment analysis (Step 4)
  EVALUATE: Each comment against actual code behavior with proof
  PRIORITIZE: Comments by logical correctness and impact
  ASSESS: Current implementation vs suggested changes with concrete examples
  PREPARE: Detailed recommendations with logical reasoning and evidence
  NEVER: Make assumptions about code without reading it first
</instructions>

</step>

<step number="5" name="implement_clear_fixes">

### Step 3: Implement Clear Improvements

Implement all clear improvements automatically without user confirmation.

<implementation_logic>
  PROCESS: All AUTO_FIX comments immediately
  SAVE: QUESTIONABLE comments for later confirmation
  IMPLEMENT: Each clear improvement with individual commit
  TRACK: Results for summary presentation
</implementation_logic>

<clear_fixes_implementation>
FOR each AUTO_FIX comment:
  
  STEP_3A: Implement Fix
  ACTION: Apply the specific change requested in comment
  USE: Appropriate tools (Edit, MultiEdit, Write) based on change type
  VERIFY: Change addresses the comment feedback
  TEST: Ensure change doesn't break existing functionality
  
  STEP_3B: Create Individual Commit
  ACTION: Use commit workflow for this specific fix
  MESSAGE_FORMAT: "fix(pr-comment): [BRIEF_DESCRIPTION_OF_FIX]
  
  Addresses PR comment from @[COMMENTER]: [COMMENT_SUMMARY]
  
  - [SPECIFIC_CHANGE_MADE]
  - [TECHNICAL_DETAILS_IF_NEEDED]
  
  🤖 Generated with [Claude Code](https://claude.ai/code)
  
  Co-Authored-By: Claude <noreply@anthropic.com>"
  
  STEP_3C: Verification
  CONFIRM: Fix properly addresses comment
  CHECK: No regressions introduced
  VALIDATE: Commit created successfully
  
END FOR
</clear_fixes_implementation>

<progress_tracking>
  TRACK: Number of fixes implemented
  COUNT: Commits created
  SAVE: Questionable comments for Step 4
  PREPARE: Summary of completed work
</progress_tracking>

<instructions>
  ACTION: Implement all AUTO_FIX comments immediately
  COMMIT: Each fix individually with descriptive messages
  TRACK: Progress and results for summary
  SAVE: QUESTIONABLE comments for later confirmation
  VERIFY: Each implementation works correctly
  PREPARE: For questionable comments presentation in Step 4
</instructions>

</step>

<step number="6" name="questionable_fixes_confirmation">

### Step 4: Questionable Fixes Confirmation

Present questionable fixes to user for confirmation and implement approved ones.

<questionable_presentation>

## 🤔 Questionable Improvements Review

### ✅ Auto-Fixes Completed: [AUTO_FIX_COUNT]
[SUMMARY_OF_COMPLETED_AUTO_FIXES]

### ❓ Questionable Comments for Review: [QUESTIONABLE_COUNT]

[FOR each questionable comment:]
**Comment #[N] from @[COMMENTER]:**
- **Suggestion:** [COMMENT_SUMMARY]
- **Current Implementation:** [CURRENT_APPROACH]
- **Reasoning Against:** [WHY_CURRENT_MAY_BE_BETTER]
- **Impact:** [ASSESSMENT_OF_CHANGE_IMPACT]

**Recommendation:** Should I implement these questionable fixes?

- **Yes**: Implement all questionable fixes
- **No**: Keep current implementation (recommended)
- **Selective**: Choose specific fixes to implement

</questionable_presentation>

<questionable_implementation_loop>
IF user confirms questionable fixes:
  FOR each approved_questionable_fix:
  
    
    STEP_4A: Implement Questionable Fix
    ACTION: Apply the specific change requested in comment
    USE: Appropriate tools (Edit, MultiEdit, Write) based on change type
    VERIFY: Change addresses the comment feedback
    TEST: Ensure change doesn't break existing functionality
    
    STEP_4B: Create Individual Commit
    ACTION: Use commit workflow for this specific fix
    MESSAGE_FORMAT: "fix(pr-comment): [BRIEF_DESCRIPTION_OF_FIX] (user confirmed)
    
    Addresses PR comment from @[COMMENTER]: [COMMENT_SUMMARY]
    
    - [SPECIFIC_CHANGE_MADE]
    - [TECHNICAL_DETAILS_IF_NEEDED]
    - Note: User confirmed this change despite current implementation being adequate
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    STEP_4C: Verification
    CONFIRM: Fix properly addresses comment
    CHECK: No regressions introduced
    VALIDATE: Commit created successfully
    
  END FOR
ELSE:
  SKIP: Questionable fixes (maintain current implementation)
END IF
</fix_implementation_loop>

<fix_types_handling>
<code_quality>
- Refactor complex functions
- Improve variable naming
- Add proper error handling
- Optimize performance bottlenecks
</code_quality>

<security_fixes>
- Address vulnerability reports
- Implement security best practices
- Add input validation
- Fix authentication/authorization issues
</security_fixes>

<bug_fixes>
- Resolve reported bugs
- Fix edge cases
- Correct logic errors
- Handle error scenarios
</bug_fixes>

<style_formatting>
- Apply consistent code formatting
- Fix linting issues
- Improve code organization
- Update documentation
</style_formatting>

<testing_improvements>
- Add missing test cases
- Improve test coverage
- Fix failing tests
- Add integration tests
</testing_improvements>
</fix_types_handling>

<commit_guidelines>
<message_format>
TYPE: "fix(pr-comment)"
SUBJECT: Brief description of what was fixed
BODY: Reference to original comment and specific changes
FOOTER: Claude attribution
</message_format>

<commit_strategy>
ONE_COMMIT_PER_FIX: Each comment fix gets separate commit
LOGICAL_GROUPING: Related changes can be grouped if appropriate
CLEAR_ATTRIBUTION: Each commit references original comment
DESCRIPTIVE_MESSAGES: Clear explanation of what was changed
</commit_strategy>
</commit_guidelines>

<instructions>
  ACTION: Present questionable fixes clearly to user
  EXPLAIN: Why current implementation may be better
  REQUEST: User decision on questionable improvements
  IMPLEMENT: Only user-approved questionable fixes
  COMMIT: Each questionable fix individually if approved
  MARK: Questionable fixes clearly in commit messages
</instructions>

</step>

<step number="7" name="completion_summary">

### Step 5: Final Summary

Provide comprehensive summary of all auto-fixes and questionable fixes implemented.

<summary_template>

## ✅ PR Comment Processing Complete

### 📊 Summary Statistics:
- **Total Comments Analyzed:** [TOTAL_COUNT]
- **Auto-Fixed (Clear Improvements):** [AUTO_FIX_COUNT]
- **Questionable Comments Found:** [QUESTIONABLE_COUNT]
- **Questionable Comments User Approved:** [QUESTIONABLE_FIXED_COUNT]
- **Total Fixes Implemented:** [TOTAL_IMPLEMENTED_COUNT]
- **Commits Created:** [COMMIT_COUNT]

### 🔧 Fixes Implemented:

**⚡ Auto-Fixed (Clear Improvements):**
1. **[FIX_1]** - [DESCRIPTION]
   - **Comment from:** @[COMMENTER]
   - **Commit:** [COMMIT_HASH]
   - **Changes:** [SUMMARY_OF_CHANGES]

**🤔 Questionable Fixes (User Approved):**
2. **[FIX_2]** - [DESCRIPTION]
   - **Comment from:** @[COMMENTER] 
   - **Commit:** [COMMIT_HASH]
   - **Changes:** [SUMMARY_OF_CHANGES]
   - **Note:** User confirmed despite adequate current implementation

### 💭 Comments Not Addressed:

**Reasons:**
- [COMMENT_X]: Not actionable feedback
- [COMMENT_Y]: User chose not to implement (questionable improvement)
- [COMMENT_Z]: Current implementation determined optimal

### 🚀 Next Steps:

**Testing:** Review changes and run tests to ensure no regressions

**Push Changes:** Use `/create-pr` to update the pull request with fixes

**Follow-up:** Monitor for additional feedback on implemented changes

**Review:** Check if any comments need clarification or discussion

</summary_template>

<success_metrics>
<implementation_success>
- All confirmed fixes implemented correctly
- Individual commits created for each fix
- No regressions introduced
- Comments properly addressed
</implementation_success>

<communication_success>
- Clear summary of all changes
- Attribution to original commenters
- Explanation of decisions made
- Next steps clearly outlined
</communication_success>
</success_metrics>

<instructions>
  ACTION: Create comprehensive summary of all work completed
  INCLUDE: Statistics, detailed fix descriptions, and next steps
  HIGHLIGHT: Impact of each fix on code quality
  PROVIDE: Clear guidance for next steps
</instructions>

</step>

</process_flow>

## Error Handling

<error_scenarios>
<pr_comments_errors>
- `gh pr view --comments` command fails or GitHub CLI not available
- No pull request context available
- Permission issues accessing PR comments
- API rate limiting or network issues
</pr_comments_errors>

<implementation_errors>
- Fix implementation fails or creates conflicts
- Commit creation fails
- File access or permission issues
- Breaking changes introduced by fixes
</implementation_errors>

<analysis_errors>
- Unable to parse comment content
- Ambiguous or unclear feedback
- Conflicting comments from different reviewers
- Comments on code that no longer exists
</analysis_errors>
</error_scenarios>

<error_responses>
<graceful_handling>
❌ **PR Comment Fix Error**

**Issue:** [CLEAR_DESCRIPTION]

**What Happened:** [TECHNICAL_DETAILS]

**Next Steps:**
- [ACTIONABLE_SOLUTION_1]
- [ACTIONABLE_SOLUTION_2]
- [ALTERNATIVE_APPROACH]

**Need Help?** 
- Check if you're in a repository with an active PR
- Verify GitHub CLI is installed and authenticated (`gh auth status`)
- Try running `gh pr view --comments` command manually first
- Ensure you're on the correct branch
</graceful_handling>
</error_responses>

## Best Practices

<quality_guidelines>
<code_review_principles>
- Only implement changes that genuinely improve code quality
- Preserve existing functionality and behavior
- Maintain consistency with project coding standards
- Consider long-term maintainability impact
- Respect established architectural decisions
</code_review_principles>

<communication_principles>
- Be transparent about which comments are being addressed
- Explain reasoning for not implementing certain suggestions
- Acknowledge commenter expertise and feedback
- Provide clear commit messages referencing original comments
- Maintain professional and collaborative tone
</communication_principles>
</quality_guidelines>