# Spec Requirements Document

> Spec: Configurable File Copy for gwt-create
> Created: 2025-08-10
> Status: Planning

## Overview

Enhance the gwt-create function to automatically copy user-specified development files (such as .claude, .agent-os, CLAUDE.md) to new worktrees, allowing users to configure once which files or directories should be copied for consistent development environment setup.

## User Stories

### Development Environment Consistency

As a developer using git worktrees, I want to automatically copy my development configuration files to new worktrees, so that I have a consistent development environment without manual setup.

When creating a new worktree, the system will copy predefined files and directories (like .claude, .agent-os, CLAUDE.md, IDE configs) from the main worktree to the new one, ensuring my development tools and settings are immediately available.

## Spec Scope

1. **Configuration System** - Create a configuration mechanism to specify which files/directories should be copied
2. **File Copy Integration** - Integrate file copying functionality into the existing gwt-create function  
3. **User-Friendly Configuration** - Provide easy setup and modification of copy rules
4. **Error Handling** - Handle missing files, permission issues, and copy failures gracefully
5. **Documentation** - Update function documentation and usage examples

## Out of Scope

- Syncing changes back to the original files
- Real-time file synchronization between worktrees
- Complex file transformation or processing during copy
- Cross-platform compatibility beyond zsh

## Expected Deliverable

1. Users can configure which development files are copied to new worktrees through a simple configuration method
2. The gwt-create function automatically copies configured files when creating new worktrees
3. Clear error messages are displayed when file copying fails, without breaking worktree creation

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-10-gwt-config-file-copy/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-10-gwt-config-file-copy/sub-specs/technical-spec.md