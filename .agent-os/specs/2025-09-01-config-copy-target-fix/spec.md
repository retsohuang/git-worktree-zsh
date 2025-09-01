# Spec Requirements Document

> Spec: Config Copy Target Fix
> Created: 2025-09-01
> Status: Planning

## Overview

The current hierarchical config discovery system has a bug in the file copying logic. When `.gwt-config` files are located in subdirectories (e.g., `/monorepo/frontend/.gwt-config`), the config files specified in these configurations are being copied to the root of the worktree instead of maintaining the proper subdirectory structure.

This creates a mismatch between where files are expected to be (in their original subdirectory structure) and where they actually end up (in the worktree root), breaking the intended workflow for monorepo projects.

Additionally, duplicate copy log messages are being displayed during the copying process, creating confusion about what files are actually being copied and where.

## User Stories

**As a monorepo developer working in a subdirectory,**
I want config files to be copied to the correct subdirectory path in my worktree
So that my development environment maintains the same structure as the source repository.

**As a developer using the gwt-create command,**
I want clear, non-duplicated log messages about file copying
So that I can understand exactly what files are being copied and where they're placed.

**As a developer with nested project configurations,**
I want the config copy process to respect the hierarchical structure of my repository
So that each subdirectory's configuration files are placed in the corresponding location in the worktree.

## Spec Scope

### Primary Issues to Fix

1. **Incorrect Target Directory**: Fix the file copying logic to preserve subdirectory structure when copying config files from `.gwt-config` found in subdirectories

2. **Duplicate Log Messages**: Eliminate duplicate copy operation log messages during the file copying process

### Technical Requirements

1. **Path Preservation Logic**: Implement logic to calculate the correct target directory based on the location of the `.gwt-config` file
   - If `.gwt-config` is in `/monorepo/frontend/`, files should copy to `{worktree}/frontend/`
   - If `.gwt-config` is in repository root, files should copy to `{worktree}/`

2. **Hierarchical Config Integration**: Ensure the fix works properly with the existing hierarchical config discovery system

3. **Log Message Deduplication**: Review and fix the logging mechanism to prevent duplicate messages

### Validation Criteria

1. Config files from subdirectory `.gwt-config` files are copied to the correct subdirectory in the worktree
2. Config files from root `.gwt-config` files continue to work as expected (copy to worktree root)
3. No duplicate log messages are shown during the copying process
4. Existing hierarchical config discovery functionality remains intact

## Out of Scope

1. **New Configuration Options**: No new configuration file syntax or options will be added
2. **Performance Optimizations**: Focus is on correctness, not performance improvements
3. **UI/UX Changes**: No changes to command-line interface or user interaction patterns
4. **Cross-Platform Testing**: Focus on core functionality; platform-specific testing is secondary
5. **Legacy Config Format Support**: Only current `.gwt-config` format needs to be supported

## Expected Deliverable

### Code Changes

1. **Fixed File Copy Logic**: Updated `_gwt_copy_config_files` function (or related functions) to:
   - Calculate correct target directory based on `.gwt-config` location
   - Preserve subdirectory structure when copying files
   - Handle both root and subdirectory config files correctly

2. **Deduplication Fix**: Updated logging mechanism to prevent duplicate copy messages

### Testing Requirements

1. **Core Test Coverage**: Test cases for both root and subdirectory `.gwt-config` scenarios
2. **Integration Testing**: Verify compatibility with existing hierarchical config discovery
3. **Regression Testing**: Ensure existing functionality continues to work

### Documentation Updates

1. **Behavior Clarification**: Update any relevant documentation to clarify how config file copying works with subdirectory configurations
2. **Example Updates**: Ensure examples reflect the correct behavior

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-01-config-copy-target-fix/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-01-config-copy-target-fix/sub-specs/technical-spec.md