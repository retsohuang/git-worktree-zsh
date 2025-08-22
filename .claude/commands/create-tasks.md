---
allowed-tools: mcp__filesystem__read_text_file
---

# Create Tasks

Create a tasks list with sub-tasks to execute a feature based on its spec.

## Instructions Validation
MANDATORY: Before proceeding with any task, you MUST first use mcp__filesystem__read_text_file to read and understand the instructions located in @~/.agent-os/instructions/core/create-tasks.md

Validation steps:
1. Use mcp__filesystem__read_text_file to read the instructions file: @~/.agent-os/instructions/core/create-tasks.md
2. Confirm that the instructions have been successfully loaded and understood
3. Only after successful validation, proceed with the product task workflow described in the instructions

If the instructions file cannot be read or accessed, STOP and report the error to the user rather than proceeding without proper guidance.
