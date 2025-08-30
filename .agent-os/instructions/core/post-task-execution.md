---
description: Rules to execute user-configurable actions after completing a single task
alwaysApply: false
version: 1.0
encoding: UTF-8
allowed-tools: Read, Task, Bash, Glob, Grep, mcp__git__git_status
---

# Post-Task Execution Rules

## Overview

Execute user-configurable actions after completing a single task, allowing customization of what happens when each individual task finishes.

<pre_flight_check>
  EXECUTE: @.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" name="configuration_check">

### Step 1: Configuration Check

Check if user has configured any post-task execution actions by looking for configuration files.

<configuration_sources>
  <primary_config>[SPEC_FOLDER]/post-task-actions.yml</primary_config>
  <fallback_config>@.agent-os/config/post-task-actions.yml</fallback_config>
</configuration_sources>

<configuration_priority>
  1. Spec-specific config: [SPEC_FOLDER]/post-task-actions.yml (highest priority)
  2. Global config: @.agent-os/config/post-task-actions.yml
  3. Default actions (if no config found)
</configuration_priority>

<instructions>
  ACTION: Check configuration files efficiently (already confirmed to exist by execute-task.md)
  READ: Available configuration files in priority order using Read tool
  PARSE: User-defined post-task actions from found configuration
  DEFAULT: Use minimal default actions if parsing fails or configs are disabled
  CONTEXT: Pass current task information to configuration processing
  EFFICIENT: File existence already verified, focus on content parsing with Read tool
</instructions>

</step>

<step number="2" name="task_context_gathering">

### Step 2: Task Context Gathering

Gather context about the completed task to provide to user-configured actions.

<task_context>
  <basic_info>
    - Parent task number and description
    - Completed sub-tasks
    - Task execution time
    - Files modified during task
    - Technology stack used
  </basic_info>
  
  <execution_context>
    - Current spec folder path
    - Git branch information
    - Test results from task execution
    - Any blocking issues encountered
    - Task completion status
  </execution_context>
</task_context>

<context_format>
  TASK_NUMBER: [PARENT_TASK_NUMBER]
  TASK_DESCRIPTION: [TASK_DESCRIPTION]
  SUB_TASKS_COMPLETED: [LIST_OF_SUBTASKS]
  SPEC_FOLDER: [SPEC_FOLDER_PATH]
  BRANCH: [CURRENT_BRANCH]
  FILES_MODIFIED: [LIST_OF_MODIFIED_FILES]
  TECH_STACK: [TECHNOLOGY_USED]
  COMPLETION_STATUS: [SUCCESS|BLOCKED|PARTIAL]
  EXECUTION_TIME: [START_TIME] to [END_TIME]
</context_format>

<instructions>
  ACTION: Collect comprehensive task context
  GATHER: All relevant information about completed task
  FORMAT: Context for user-configured actions
  PREPARE: Data structure for action execution
</instructions>

</step>

<step number="3" name="conditional_action_execution">

### Step 3: Conditional Action Execution

Execute user-configured actions based on conditions and task context.

<action_types>
  <notification_actions>
    - Send completion notifications
    - Play custom sounds
    - Log task completion
    - Update external systems
  </notification_actions>
  
  <analysis_actions>
    - Run custom analysis on modified code
    - Generate task-specific reports
    - Validate implementation against criteria
    - Check code quality metrics
  </analysis_actions>
  
  <integration_actions>
    - Run subset of tests
    - Update documentation
    - Sync with external tools
    - Trigger custom workflows
  </integration_actions>
  
  <prompt_actions>
    - Execute custom prompts with task context
    - Run subagents with specific instructions
    - Generate task-specific summaries
    - Create follow-up task suggestions
  </prompt_actions>
</action_types>

<conditional_execution>
  <condition_types>
    - Task type (feature, bugfix, refactor, etc.)
    - Technology stack used
    - Files modified pattern
    - Task completion status
    - Spec category
    - Time of day/week
  </condition_types>
  
  <execution_flow>
    FOR each configured action:
      EVALUATE condition against task context
      IF condition matches:
        EXECUTE action with task context
        LOG action execution result
      ELSE:
        SKIP action
    END FOR
  </execution_flow>
</conditional_execution>

<instructions>
  ACTION: Execute configured actions based on conditions
  EVALUATE: Each action's conditions against task context
  EXECUTE: Matching actions with proper context
  LOG: Action execution results for debugging
  HANDLE: Action failures gracefully
</instructions>

</step>

<step number="4" name="user_prompt_execution">

### Step 4: User Prompt Execution

Execute user-defined prompts with task context if configured.

<prompt_execution>
  <prompt_sources>
    - Inline prompts in configuration
    - Referenced prompt files
    - Dynamic prompts based on task type
    - Template prompts with context substitution
  </prompt_sources>
  
  <context_injection>
    REPLACE: {{TASK_NUMBER}} with actual task number
    REPLACE: {{TASK_DESCRIPTION}} with task description
    REPLACE: {{FILES_MODIFIED}} with list of modified files
    REPLACE: {{SPEC_FOLDER}} with spec folder path
    REPLACE: {{BRANCH}} with current branch
    REPLACE: {{TECH_STACK}} with technology used
    REPLACE: {{COMPLETION_STATUS}} with completion status
  </context_injection>
  
  <execution_methods>
    - Direct prompt execution
    - Subagent execution with custom prompts
    - Tool execution with prompt-generated parameters
    - Chain of prompts with context passing
  </execution_methods>
</prompt_execution>

<error_handling>
  <prompt_errors>
    - Invalid prompt syntax
    - Missing context variables
    - Subagent execution failures
    - Tool execution errors
  </prompt_errors>
  
  <recovery_actions>
    - Log error details
    - Skip failed prompt
    - Use fallback prompt if available
    - Continue with next action
  </recovery_actions>
</error_handling>

<instructions>
  ACTION: Execute user-defined prompts with task context
  INJECT: Task context into prompt templates
  EXECUTE: Prompts using appropriate methods
  HANDLE: Errors gracefully without stopping flow
  LOG: Prompt execution results
</instructions>

</step>

<step number="5" name="completion_summary">

### Step 5: Post-Task Execution Summary

Provide summary of executed post-task actions if any were run.

<summary_format>
  ## 📋 Post-Task Actions Executed
  
  **Task:** [TASK_NUMBER] - [TASK_DESCRIPTION]
  
  **Actions Run:**
  - ✅ [ACTION_1] - [RESULT]
  - ✅ [ACTION_2] - [RESULT]
  - ⚠️ [FAILED_ACTION] - [ERROR_MESSAGE] (if any)
  
  **Next:** Continue with next task or proceed to next step
</summary_format>

<summary_conditions>
  <show_when>
    - Any actions were executed
    - Actions failed and user should know
    - Debugging mode is enabled
  </show_when>
  
  <skip_when>
    - No actions configured
    - All actions skipped due to conditions
    - Silent mode is enabled
  </skip_when>
</summary_conditions>

<instructions>
  ACTION: Generate summary if applicable
  INCLUDE: Executed actions and results
  HIGHLIGHT: Any failures or important results
  SKIP: Summary if no actions were run
</instructions>

</step>

</process_flow>

<post_flight_check>
  EXECUTE: @.agent-os/instructions/meta/post-flight.md
</post_flight_check>