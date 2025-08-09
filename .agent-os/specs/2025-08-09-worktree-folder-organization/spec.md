# Spec Requirements Document

> Spec: Worktree Folder Organization
> Created: 2025-08-09
> Status: Planning

## Overview

Improve the `gwt-create` command to organize git worktrees into a dedicated folder structure using the pattern "{original-project-folder}-worktrees/" instead of creating sibling directories directly in the parent directory. This will provide better organization and prevent worktree directories from cluttering the parent directory alongside the main project folder.

## User Stories

As a developer using git worktrees, I want:
- My worktrees to be organized in a dedicated subfolder so they don't clutter my projects directory
- A predictable folder structure that follows the pattern "{original-project-folder}-worktrees/"
- The ability to easily identify which worktrees belong to which main project
- Backward compatibility with existing worktree setups

## Spec Scope

- Modify the `gwt-create` function to use the new folder organization pattern
- Create worktrees in "{original-project-folder}-worktrees/{branch-name}" structure
- Automatically create the worktrees parent directory if it doesn't exist
- Maintain all existing functionality of the gwt-create command
- Provide clear error messages if directory creation fails
- Update any helper functions that might be affected by the path change

## Out of Scope

- Migration of existing worktrees to the new structure (users can do this manually)
- Changes to other git worktree commands beyond gwt-create
- Configuration options to customize the folder naming pattern
- Integration with git worktree list or cleanup commands

## Expected Deliverable

Enhanced `gwt-create` function in `git-worktree.zsh` that:
1. Determines the original project folder name
2. Creates a "{original-project-folder}-worktrees/" directory in the parent of the current project
3. Creates the new worktree inside this organized structure
4. Maintains all existing error handling and user feedback
5. Works with both new and existing branch scenarios

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-09-worktree-folder-organization/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-09-worktree-folder-organization/sub-specs/technical-spec.md