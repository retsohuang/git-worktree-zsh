# Spec Requirements Document

> Spec: Monorepo Config Discovery Enhancement
> Created: 2025-08-30
> Status: Planning

## Overview

Enhance the .gwt-config file discovery mechanism in gwt-create to support monorepo workflows with .gitignore-like configuration inheritance. The system will collect all .gwt-config files from the current directory up to the git root and merge them, with closer configurations taking precedence over parent configurations.

## User Stories

### Project-Specific Configuration in Monorepos

As a developer working in a monorepo with multiple projects, I want gwt-create to find and use the .gwt-config file specific to my current project directory, so that each project can have its own set of development files copied to worktrees without interfering with other projects in the same repository.

When I'm working in `/monorepo/frontend/` with both `/monorepo/frontend/.gwt-config` and `/monorepo/.gwt-config` files, gwt-create should merge both configurations with the frontend config taking precedence, ensuring that both shared repository files and frontend-specific development files are copied to new worktrees.

### Transparent Configuration Discovery

As a user, I want to understand which configuration file is being used when gwt-create copies files, so that I can debug configuration issues and ensure the correct project-specific settings are applied.

The system should provide clear feedback about all configuration files found and merged, helping me verify that the intended project and parent configurations are active and understand the precedence order.

## Spec Scope

1. **Hierarchical Config Collection** - Walk up directory tree from current directory to git root collecting all .gwt-config files found
2. **Configuration Merging** - Merge all collected configurations with .gitignore-like precedence (closer configs override parent configs)
3. **Exclusion Pattern Handling** - Process exclusion patterns (`!`) with proper precedence across merged configurations
4. **Enhanced Logging** - Provide clear feedback about all config files found and the final merged configuration
5. **Backward Compatibility** - Maintain existing behavior for single configuration scenarios

## Out of Scope

- Configuration file validation beyond current parsing logic
- Cross-platform path handling beyond standard zsh capabilities
- Support for config files with different names or extensions
- Project workspace detection or integration with specific monorepo tools
- Complex merging strategies beyond .gitignore-like precedence rules

## Expected Deliverable

1. Users in monorepo subdirectories automatically receive merged configuration from all .gwt-config files in the directory hierarchy
2. Configuration inheritance works like .gitignore with closer files overriding parent configurations and exclusion patterns working across the merged set
3. Clear logging output shows all configuration files found and the final merged configuration for transparency and debugging

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-30-monorepo-config-discovery/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-30-monorepo-config-discovery/sub-specs/technical-spec.md