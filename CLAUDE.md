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

### Validation
```bash
# Check zsh syntax
zsh -n git-worktree.zsh

# Run shellcheck if available
shellcheck git-worktree.zsh
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

## Function Design Patterns

- Use zsh parameter expansion for argument handling
- Implement proper error checking with meaningful exit codes
- Use local variables to avoid namespace pollution
- Follow zsh best practices for function naming and structure

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