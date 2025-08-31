---
description: Rules to execute a task and its sub-tasks using Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Task Execution Rules

## Overview

Execute a specific task along with its sub-tasks systematically following a TDD development workflow.

**🔥 CRITICAL WORKFLOW REMINDER**: This process has 8 mandatory steps. Step 8 (Post-Task Execution Actions) is REQUIRED after every task completion and must NOT be skipped.

<pre_flight_check>
  EXECUTE: @.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>


<process_flow>

## ⚠️ MANDATORY WORKFLOW STEPS (ALL 8 STEPS MUST BE COMPLETED)
Steps 1-6: Task analysis and implementation
Step 7: Update tasks.md status 
Step 8: **CRITICAL** - Execute post-task actions (NEVER SKIP THIS STEP)

<step number="1" name="task_understanding">

### Step 1: Task Understanding

Read and analyze the given parent task and all its sub-tasks from tasks.md to gain complete understanding of what needs to be built.

<task_analysis>
  <read_from_tasks_md>
    - Parent task description
    - All sub-task descriptions
    - Task dependencies
    - Expected outcomes
  </read_from_tasks_md>
</task_analysis>

<instructions>
  ACTION: Read the specific parent task and all its sub-tasks
  ANALYZE: Full scope of implementation required
  UNDERSTAND: Dependencies and expected deliverables
  NOTE: Test requirements for each sub-task
</instructions>

</step>

<step number="2" name="technical_spec_review">

### Step 2: Technical Specification Review

Search and extract relevant sections from technical-spec.md to understand the technical implementation approach for this task.

<selective_reading>
  <search_technical_spec>
    FIND sections in technical-spec.md related to:
    - Current task functionality
    - Implementation approach for this feature
    - Integration requirements
    - Performance criteria
  </search_technical_spec>
</selective_reading>

<instructions>
  ACTION: Search technical-spec.md for task-relevant sections
  EXTRACT: Only implementation details for current task
  SKIP: Unrelated technical specifications
  FOCUS: Technical approach for this specific feature
</instructions>

</step>

<step number="3" subagent="context-fetcher" name="best_practices_review">

### Step 3: Best Practices Review

Use the context-fetcher subagent to retrieve relevant sections from @.agent-os/standards/best-practices.md that apply to the current task's technology stack and feature type.

<selective_reading>
  <search_best_practices>
    FIND sections relevant to:
    - Task's technology stack
    - Feature type being implemented
    - Testing approaches needed
    - Code organization patterns
  </search_best_practices>
</selective_reading>

<instructions>
  ACTION: Use context-fetcher subagent
  REQUEST: "Find best practices sections relevant to:
            - Task's technology stack: [CURRENT_TECH]
            - Feature type: [CURRENT_FEATURE_TYPE]
            - Testing approaches needed
            - Code organization patterns"
  PROCESS: Returned best practices
  APPLY: Relevant patterns to implementation
</instructions>

</step>

<step number="4" subagent="context-fetcher" name="code_style_review">

### Step 4: Code Style Review

Use the context-fetcher subagent to retrieve relevant code style rules from @.agent-os/standards/code-style.md for the languages and file types being used in this task.

<selective_reading>
  <search_code_style>
    FIND style rules for:
    - Languages used in this task
    - File types being modified
    - Component patterns being implemented
    - Testing style guidelines
  </search_code_style>
</selective_reading>

<instructions>
  ACTION: Use context-fetcher subagent
  REQUEST: "Find code style rules for:
            - Languages: [LANGUAGES_IN_TASK]
            - File types: [FILE_TYPES_BEING_MODIFIED]
            - Component patterns: [PATTERNS_BEING_IMPLEMENTED]
            - Testing style guidelines"
  PROCESS: Returned style rules
  APPLY: Relevant formatting and patterns
</instructions>

</step>

<step number="5" name="task_execution">

### Step 5: Task and Sub-task Execution

Execute the parent task and all sub-tasks in order using test-driven development (TDD) approach.

<typical_task_structure>
  <first_subtask>Write tests for [feature]</first_subtask>
  <middle_subtasks>Implementation steps</middle_subtasks>
  <final_subtask>Verify all tests pass</final_subtask>
</typical_task_structure>

<execution_order>
  <subtask_1_tests>
    IF sub-task 1 is "Write tests for [feature]":
      - Write all tests for the parent feature
      - Include unit tests, integration tests, edge cases
      - Run tests to ensure they fail appropriately
      - Mark sub-task 1 complete
  </subtask_1_tests>

  <middle_subtasks_implementation>
    FOR each implementation sub-task (2 through n-1):
      - Implement the specific functionality
      - Make relevant tests pass
      - Update any adjacent/related tests if needed
      - Refactor while keeping tests green
      - Mark sub-task complete
  </middle_subtasks_implementation>

  <final_subtask_verification>
    IF final sub-task is "Verify all tests pass":
      - Run entire test suite
      - Fix any remaining failures
      - Ensure no regressions
      - Mark final sub-task complete
  </final_subtask_verification>
</execution_order>

<test_management>
  <new_tests>
    - Written in first sub-task
    - Cover all aspects of parent feature
    - Include edge cases and error handling
  </new_tests>
  <test_updates>
    - Made during implementation sub-tasks
    - Update expectations for changed behavior
    - Maintain backward compatibility
  </test_updates>
</test_management>

<instructions>
  ACTION: Execute sub-tasks in their defined order
  RECOGNIZE: First sub-task typically writes all tests
  IMPLEMENT: Middle sub-tasks build functionality
  VERIFY: Final sub-task ensures all tests pass
  UPDATE: Mark each sub-task complete as finished
</instructions>

</step>

<step number="6" subagent="test-runner" name="task_test_verification">

### Step 6: Task-Specific Test Verification

Use the test-runner subagent to run and verify only the tests specific to this parent task (not the full test suite) to ensure the feature is working correctly.

<focused_test_execution>
  <run_only>
    - All new tests written for this parent task
    - All tests updated during this task
    - Tests directly related to this feature
  </run_only>
  <skip>
    - Full test suite (done later in execute-tasks.md)
    - Unrelated test files
  </skip>
</focused_test_execution>

<final_verification>
  IF any test failures:
    - Debug and fix the specific issue
    - Re-run only the failed tests
  ELSE:
    - Confirm all task tests passing
    - Ready to proceed
</final_verification>

<instructions>
  ACTION: Use test-runner subagent
  REQUEST: "Run tests for [this parent task's test files]"
  WAIT: For test-runner analysis
  PROCESS: Returned failure information
  VERIFY: 100% pass rate for task-specific tests
  CONFIRM: This feature's tests are complete
</instructions>

</step>

<step number="7" name="task_status_updates">

### Step 7: Mark this task and sub-tasks complete

IMPORTANT: In the tasks.md file, mark this task and its sub-tasks complete by updating each task checkbox to [x].

<update_format>
  <completed>- [x] Task description</completed>
  <incomplete>- [ ] Task description</incomplete>
  <blocked>
    - [ ] Task description
    ⚠️ Blocking issue: [DESCRIPTION]
  </blocked>
</update_format>

<blocking_criteria>
  <attempts>maximum 3 different approaches</attempts>
  <action>document blocking issue</action>
  <emoji>⚠️</emoji>
</blocking_criteria>

<instructions>
  ACTION: Update tasks.md after each task completion
  MARK: [x] for completed items immediately
  DOCUMENT: Blocking issues with ⚠️ emoji
  LIMIT: 3 attempts before marking as blocked
  **CRITICAL**: Do NOT proceed to next task without completing Step 8 first
</instructions>

</step>

<step number="8" name="post_task_execution">

### Step 8: Post-Task Execution Actions [MANDATORY]

**🔥 CRITICAL**: This step is MANDATORY and must ALWAYS be executed after completing any task. 

Execute user-configurable post-task actions to allow customization of what happens when each individual task completes.

<post_task_context>
  <task_information>
    - Current parent task number and description
    - All completed sub-tasks
    - Files modified during task execution
    - Technology stack used in task
    - Task completion status and any blocking issues
  </task_information>
  
  <execution_context>
    - Current spec folder path
    - Git branch information
    - Task execution timing
    - Test results from task verification
  </execution_context>
</post_task_context>

<conditional_execution>
  <lightweight_config_check>
    STEP_1: Use Bash(ls .agent-os/config/post-task-actions.yml) to check global config
    STEP_2: IF config file exists:
             EXECUTE: @.agent-os/instructions/core/post-task-execution.md
             PROVIDE: Complete task context for action execution
           ELSE:
             SKIP: Post-task execution (no configuration found)
  </lightweight_config_check>
  
  <efficient_checking>
    AVOID: Reading file contents during check
    USE: Only directory listing and file existence checks
    PRINCIPLE: Check file existence before reading content
    FALLBACK: If directory check fails, assume no configuration
  </efficient_checking>
  
  <context_passing>
    TASK_NUMBER: [CURRENT_PARENT_TASK_NUMBER]
    TASK_DESCRIPTION: [CURRENT_TASK_DESCRIPTION]
    SUB_TASKS: [LIST_OF_COMPLETED_SUBTASKS]
    SPEC_FOLDER: [CURRENT_SPEC_FOLDER_PATH]
    FILES_MODIFIED: [FILES_CHANGED_IN_THIS_TASK]
    COMPLETION_STATUS: [SUCCESS|BLOCKED]
  </context_passing>
</conditional_execution>

<instructions>
  **🚨 MANDATORY EXECUTION ORDER**:
  
  STEP_A: ALWAYS use lightweight file existence check for YAML configuration file
  STEP_B: CHECK .agent-os/config/post-task-actions.yml using Bash(ls)
  STEP_C: IF config file exists:
           - MUST EXECUTE @.agent-os/instructions/core/post-task-execution.md  
           - MUST PROVIDE complete task context
           - DO NOT proceed until post-task execution completes
         ELSE:
           - LOG: "No post-task configuration found, skipping post-task actions"
           - CONTINUE: Proceed normally
  
  **⚠️ FAILURE TO EXECUTE STEP 8 IS A CRITICAL WORKFLOW ERROR**
  
  EFFICIENT: Use simple ls command, avoid reading file contents during existence check
</instructions>

</step>

</process_flow>

<post_flight_check>
  EXECUTE: @.agent-os/instructions/meta/post-flight.md
</post_flight_check>
