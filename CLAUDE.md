# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project implements zsh functions for creating and managing git worktrees. Git worktrees allow you to check out multiple branches of the same repository into separate working directories.

## Development Commands

### Testing zsh Functions

```bash
# Source the function file to test changes
source ./git-worktree.zsh

# Test function directly in zsh
zsh -c "source ./git-worktree.zsh && your_function_name"
```

### Validation & Testing

```bash
# Check zsh syntax
zsh -n git-worktree.zsh

# Run shellcheck if available
shellcheck git-worktree.zsh

# === Layered Testing Strategy ===
# This replaces the previous single test file approach

# Quick smoke tests (9 tests - recommended for development)
bats test/test_gwt_create.bats

# Comprehensive layered testing (70 tests total - recommended for CI/validation)
./scripts/test-layered.sh

# Individual test layers:
# Core tests (9 tests - MUST pass) - Core value proposition
bats test/core/

# Unit tests (10 tests - MUST pass) - Individual function testing
bats test/unit/

# Integration tests (7 tests - MUST pass for release) - End-to-end workflows
bats test/integration/

# Environment tests (9 tests - failures allowed) - Platform/environment specific
bats test/environment/ || echo "Environment tests failed - this is acceptable"

# Run all critical tests (61 tests)
bats test/core/ test/unit/ test/integration/

# === Test Helper Functions ===
# For zsh-specific functionality that doesn't work in bats' bash environment:
# Use run_in_zsh helper function defined in test/test_helper.bash
# Example: run run_in_zsh \_gwt_expand_config_patterns .gwt-config
```

## Architecture

- **Main function file**: `git-worktree.zsh` - Contains the core zsh functions for worktree management
- **Installation script**: Setup script to add functions to user's zsh configuration
- **Documentation**: Usage examples and function documentation

## Key Implementation Notes

- Use `git worktree add` command as the foundation
- Handle edge cases like existing directories and branch conflicts
- Provide user-friendly error messages
- Support both new and existing branch scenarios
- Consider integration with common zsh frameworks (oh-my-zsh, prezto)

## Spec Protection Rules

### CRITICAL: Feature Protection Guidelines

**Implemented core features must not be modified due to test issues**

1. **Test Priority Principle**：

   - When tests fail, prioritize fixing tests over changing functionality
   - Functional correctness > Test convenience
   - Any breaking change must have clear business justification

2. **Organized Folder Structure Protection**：

   - `{project-name}-worktrees/{branch-name}` structure is core value proposition
   - Must not remove this feature to make tests pass
   - Related container directory creation logic must be preserved

3. **Feature Removal Approval Process**：

   - Must create issue for discussion before removing any implemented feature
   - Must clearly explain necessity in commit message
   - Forbidden rationales: "simplification", "improve tests" for feature removal

4. **Test Fix Strategy**：

   - Environment-related test failures → Fix test environment
   - Path-related test failures → Update test expectations
   - Performance test failures → Adjust performance thresholds or test environment
   - Functional test failures → Check functional implementation issues

5. **Test Layer Priority**：
   - **Core tests failure** → STOP: Fix immediately, core functionality broken
   - **Unit tests failure** → STOP: Fix immediately, individual functions broken
   - **Integration tests failure** → WARNING: Fix before release, workflows affected
   - **Environment tests failure** → OK: May continue, environment-specific issues

## Function Design Patterns

- Use zsh parameter expansion for argument handling
- Implement proper error checking with meaningful exit codes
- Use local variables to avoid namespace pollution
- Follow zsh best practices for function naming and structure

## Documentation Maintenance

### Copilot Instructions Synchronization

- **IMPORTANT**: When making any program logic or architectural changes, also update `.github/copilot-instructions.md`
- This file provides guidance to GitHub Copilot and other AI assistants about the project structure and workflows
- Changes requiring updates include:
  - New functions or major function modifications
  - Changes to testing strategy or validation commands
  - Updates to project architecture or file structure
  - Modifications to feature protection rules
  - New development commands or workflows

### Security Guidelines Compliance

- **CRITICAL**: Follow `.agent-os/standards/security-guidelines.md` for all Agent OS workflows
- **Never expose absolute file paths** containing user information in documentation
- **Always use relative paths** from project root in generated documentation
- **Sanitize context variables** before passing to subagents
- See security guidelines for comprehensive prevention rules

## Task Execution Protocol

### CRITICAL: Task Status Tracking Rules

**Dual Tracking System: TodoWrite + tasks.md MUST be synchronized**

#### Task Completion Agreement

```
Task INCOMPLETE = TodoWrite ✓ + tasks.md ✗
Task INCOMPLETE = TodoWrite ✗ + tasks.md ✓
Task COMPLETE   = TodoWrite ✓ + tasks.md ✓
```

#### Mandatory Completion Ritual

Every time a sub-task is completed, MUST execute this sequence:

1. Implement functionality
2. Verify tests pass
3. Update TodoWrite → `"status": "completed"`
4. **IMMEDIATELY update tasks.md → `[x]`**
5. Confirm both systems are synchronized

#### Task Completion Checklist

- [ ] Functionality implemented correctly
- [ ] All tests pass
- [ ] TodoWrite updated to "completed"
- [ ] **tasks.md marked as [x]**
- [ ] Both tracking systems status consistent

#### Core Principles

- **Mantra**: "TodoWrite done, tasks.md follows immediately"
- **Atomic Operation**: Treat updating both places as one indivisible action
- **Hard Rule**: Never declare "task complete" unless tasks.md is updated

## Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

### Examples

```
feat: add gwt-create function for worktree management
fix: handle existing directory in gwt-create
docs: update README with installation instructions
refactor: improve error handling in worktree functions
```
