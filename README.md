# Git Worktree Zsh

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell: Zsh](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![Platform: macOS/Linux](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL-lightgrey.svg)](#prerequisites)
[![Git: 2.5+](https://img.shields.io/badge/Git-2.5%2B-orange.svg)](https://git-scm.com/)

A comprehensive zsh function suite for effortless git worktree management, enabling developers to work with multiple branches simultaneously in separate directories.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
  - [Manual Installation](#manual-installation)
  - [Oh My Zsh Plugin](#oh-my-zsh-plugin)
  - [Package Managers](#package-managers)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Advanced Usage](#advanced-usage)
  - [Command Reference](#command-reference)
- [Examples](#examples)
- [Development](#development)
  - [Contributing](#contributing)
  - [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)
- [Changelog](#changelog)
- [License](#license)

## Overview

Git Worktree Zsh provides intelligent automation for git worktree management, allowing developers to seamlessly switch between multiple branches without the overhead of traditional branch switching. Perfect for feature development, bug fixes, and code reviews requiring parallel work streams.

**Target Audience:**

- Developers working with multiple feature branches simultaneously
- Teams requiring parallel development workflows
- Code reviewers needing to test multiple pull requests
- Open source contributors managing complex branching strategies

## Features

### 📁 **Organized Worktree Structure**

- **Clean Organization**: Worktrees are created in dedicated "{project-name}-worktrees/" directories
- **No Directory Clutter**: Prevents scattering worktree directories across the parent directory
- **Intuitive Layout**: Easy to locate and manage multiple worktrees for the same project
- **Automatic Container Creation**: Worktree container directories are created automatically as needed

### 🚀 **Intelligent Branch Detection**

- **Smart Strategy Selection**: Automatically detects whether to create new branches or checkout existing ones
- **Local & Remote Awareness**: Seamlessly handles local branches, remote tracking branches, and new branch creation
- **Conflict Prevention**: Prevents worktree conflicts and provides clear guidance when issues arise

### 🛡️ **Robust Error Handling**

- **Comprehensive Validation**: Branch names, filesystem permissions, disk space, and git repository state
- **Helpful Error Messages**: Actionable suggestions for resolving common issues
- **Automatic Cleanup**: Failed operations are properly cleaned up to prevent corrupted state

### 🎯 **Developer Experience**

- **One-Command Workflow**: Create and navigate to worktrees in a single command
- **Organized Structure**: Worktrees are created in dedicated "{project-name}-worktrees/" directories
- **Zsh Completion**: Intelligent tab completion for branch names from local and remote repositories
- **Progress Indicators**: Color-coded output with clear status messages
- **Dry Run Mode**: Preview operations before execution

### ⚡ **Performance & Compatibility**

- **Cross-Platform**: Native support for macOS, Linux, and Windows WSL
- **Framework Integration**: Compatible with Oh My Zsh, Prezto, and other zsh frameworks
- **Minimal Dependencies**: Only requires git 2.5+ and zsh 5.0+
- **Fast Execution**: Optimized for repositories with hundreds of branches

## Installation

### Manual Installation

1. **Download the function file**:

```bash
# Create config directory if it doesn't exist
mkdir -p ~/.config

# Download the git-worktree.zsh file directly from this repository
curl -fsSL https://raw.githubusercontent.com/retsohuang/git-worktree-zsh/master/git-worktree.zsh > ~/.config/git-worktree.zsh
```

1. **Add to your zsh configuration**:

```bash
echo "source ~/.config/git-worktree.zsh" >> ~/.zshrc
```

1. **Reload your shell**:

```bash
source ~/.zshrc
```

1. **Verify installation**:

```bash
gwt-create --help
```

### Oh My Zsh Plugin

1. **Clone to custom plugins directory**:

```bash
git clone https://github.com/retsohuang/git-worktree-zsh.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-worktree
```

1. **Add to your Oh My Zsh plugins**:

```bash
# In ~/.zshrc, add git-worktree to the plugins array
plugins=(git git-worktree other-plugins)
```

1. **Restart your terminal or reload zsh**:

```bash
exec zsh
```

### Package Managers

#### Homebrew

```bash
# Coming soon
brew install git-worktree-zsh
```

#### Zinit

```bash
# Add to ~/.zshrc
zinit load "retsohuang/git-worktree-zsh"
```

**Note for Package Managers**: After adding the configuration to your `~/.zshrc` file, restart your terminal or run `source ~/.zshrc` to reload the configuration. The package managers will automatically download and install the function for you.

## Prerequisites

**Required:**

- **Git**: Version 2.5 or higher (for `git worktree` support)
- **Zsh**: Version 5.0 or higher
- **Unix-like System**: macOS, Linux, or Windows WSL

**Optional:**

- **Oh My Zsh**: For enhanced plugin integration
- **bats-core**: For running development tests

**Compatibility Matrix:**

| Platform      | Git Version | Zsh Version | Status      |
| ------------- | ----------- | ----------- | ----------- |
| macOS 10.15+  | 2.5+        | 5.0+        | ✅ Primary   |
| Ubuntu 20.04+ | 2.5+        | 5.0+        | ✅ Primary   |
| Windows WSL2  | 2.5+        | 5.0+        | ✅ Secondary |
| CentOS 8+     | 2.5+        | 5.0+        | ✅ Secondary |

## Usage

### Basic Usage

**Create a new worktree for a new branch:**

```bash
gwt-create feature/user-authentication
```

**Create a worktree with custom directory name:**

```bash
gwt-create feature/complex-name simple-auth
```

**Preview operations without making changes:**

```bash
gwt-create --dry-run experimental-branch
```

### Advanced Usage

**Work with existing branches:**

```bash
# Checkout existing local branch in new worktree
gwt-create existing-local-branch

# Create local tracking branch from remote
gwt-create origin/remote-feature-branch
```

**Complex branching scenarios:**

```bash
# Handle branches with special characters
gwt-create "feature/user-auth/oauth2.0"

# Create worktree in specific location
gwt-create hotfix/critical-bug ../hotfix-directory
```

### Command Reference

#### `gwt-create`

Create a git worktree with intelligent branch handling and automatic configuration file copying.

**Syntax:**

```bash
gwt-create <branch-name> [target-directory] [options]
```

**Parameters:**

- `branch-name`: Name of the branch to create or checkout (required)
- `target-directory`: Custom directory name (optional, defaults to sanitized branch name)

**Options:**

- `-h, --help`: Display usage information
- `--dry-run`: Show what would be done without making changes

#### Configuration File (`.gwt-config`)

Automatically copy development files and directories to new worktrees by creating a `.gwt-config` file in your repository root. This file specifies which files and directories should be copied to maintain consistent development environments across worktrees.

**Location and Directory Structure:**

The system searches for `.gwt-config` files hierarchically from the current directory up to the repository root, and **preserves directory structure** when copying files:

1. **Hierarchical Discovery**: Searches from current directory up to repository root
2. **Directory Structure Preservation**: 
   - Files from root `.gwt-config` → copy to worktree root
   - Files from subdirectory `.gwt-config` → copy to matching subdirectory in worktree
   - Example: `src/.gwt-config` entries copy to `worktree-name/src/` directory
3. **Path Context Awareness**: Each config file's location determines where its entries are copied

**File Format:**
- One file/directory path per line
- Comments start with `#`
- Empty lines are ignored
- Supports glob patterns (`*.md`, `.vscode/*`)
- Supports exclusion patterns with `!` prefix (`!README.md`)
- Whitespace is automatically trimmed

**Example Configuration Files:**

**Root `.gwt-config` (files copy to worktree root):**
```bash
# Git Worktree Configuration
# Development files to copy to new worktrees

# Claude AI configuration  
.claude

# Project documentation for Claude
CLAUDE.md

# Agent OS specifications and configuration
.agent-os/

# IDE settings
.vscode/
.idea/

# Configuration files
*.json
!package-lock.json

# Exclude temporary files
!.vscode/temp.log
```

**Subdirectory `src/.gwt-config` (files copy to `worktree-name/src/`):**
```bash  
# Frontend development configuration
# Files copy to src/ directory in worktree

# Development server config
webpack.dev.js
vite.config.js

# Environment files for this component
.env.development
.env.local

# Linting configuration specific to src
.eslintrc.js
```

**Common Use Cases:**

- **AI Development**: Copy `.claude`, `CLAUDE.md`, `.agent-os/` for Claude AI workflows
- **IDE Settings**: Copy `.vscode/`, `.idea/` for consistent editor configuration  
- **Project Configuration**: Copy config files while excluding generated ones
- **Documentation**: Copy project-specific documentation files
- **Monorepo Projects**: Use subdirectory configs for component-specific development files
- **Microservices**: Separate config files per service directory with preserved structure

**Supported Patterns:**

```bash
# Exact files
.claude
CLAUDE.md

# Directories (trailing slash recommended)
.vscode/
.agent-os/

# Glob patterns
*.md
.vscode/*
config/*.json

# Exclusions
!README.md
!.vscode/temp.log
!node_modules/
```

**Branch Strategy Detection:**

The function automatically determines the appropriate strategy:

1. **Local Branch Exists**: Creates worktree from existing local branch
2. **Remote Branch Exists**: Creates local tracking branch and worktree
3. **New Branch**: Creates new branch from current HEAD

**Directory Structure:**

Worktrees are organized in dedicated container directories:

```text
parent-directory/
├── main-repo/                    # Your original repository
└── main-repo-worktrees/         # Organized worktree container
    ├── feature-branch/          # Worktree for feature/branch
    ├── hotfix-123/              # Worktree for hotfix/123
    └── user-dashboard/          # Worktree for feature/user-dashboard
```

## Examples

### Feature Development Workflow

```bash
# Start working on a new feature
cd ~/projects/my-app
gwt-create feature/user-dashboard

# This creates:
# - New branch 'feature/user-dashboard'
# - Worktree at ~/projects/my-app-worktrees/user-dashboard/
# - Automatically navigates to the new directory

# Continue development
git add .
git commit -m "Add user dashboard components"

# Switch to working on a bug fix (in parallel)
cd ~/projects/my-app  # Back to main repo
gwt-create hotfix/login-issue

# Work on multiple features simultaneously
# Main repo:     ~/projects/my-app/
# Feature work:  ~/projects/my-app-worktrees/user-dashboard/
# Hotfix work:   ~/projects/my-app-worktrees/login-issue/
```

### Code Review Workflow

```bash
# Review a pull request locally (requires manual fetch first)
git fetch origin pull/123/head:pr/123-new-authentication
gwt-create pr/123-new-authentication

# Test an existing feature branch
gwt-create feature/oauth-integration

# Compare implementations side by side
# Each worktree is a separate directory with full git functionality
```

### Release Preparation

```bash
# Create release preparation worktree
gwt-create release/v2.1.0

# Create hotfix worktree for current release
gwt-create hotfix/v2.0.1
```

### Development Environment Consistency

```bash
# Set up root .gwt-config for project-wide files
echo ".claude\nCLAUDE.md\n.vscode/" > .gwt-config

# Set up subdirectory config for component-specific files  
mkdir -p src
echo "webpack.dev.js\n.env.local" > src/.gwt-config

# Create worktree - files copy to appropriate locations
cd src && gwt-create feature/new-dashboard

# Your development setup preserves directory structure:
# ~/projects/my-app-worktrees/new-dashboard/
# ├── .claude          # From root config → worktree root
# ├── CLAUDE.md         # From root config → worktree root
# ├── .vscode/          # From root config → worktree root
# └── src/
#     ├── webpack.dev.js    # From src/.gwt-config → worktree/src/
#     ├── .env.local        # From src/.gwt-config → worktree/src/
#     └── [source code]     # Git worktree content
```

### Error Recovery Examples

```bash
# If directory already exists
$ gwt-create feature/existing
Error: Directory '../my-project-worktrees/existing' already exists
Please choose a different directory name or remove the existing directory.

# Solution: Use custom directory name
$ gwt-create feature/existing feature-v2

# If branch is already checked out elsewhere
$ gwt-create main
Error: Failed to create worktree from local branch 'main'
Possible causes: Branch is checked out elsewhere, filesystem issues, or corrupted branch
Suggestion: Check 'git worktree list' to see where the branch might be in use
```

## Development

### Contributing

We welcome contributions! Please see our comprehensive [Contributing Guide](CONTRIBUTING.md) for detailed information on:

- Setting up your development environment
- Understanding our layered testing strategy
- Following coding standards and best practices
- Submitting pull requests
- Feature protection guidelines

**Quick Start:**
```bash
# Fork, clone, and set up
git clone https://github.com/YOUR_GITHUB_USERNAME/git-worktree-zsh.git
cd git-worktree-zsh
brew install bats-core  # or apt-get install bats

# Test your changes
./scripts/test-layered.sh

# Submit your PR with tests and documentation
```

### Architecture

**Core Components:**

- **`gwt-create`**: Main function orchestrating worktree creation
- **Validation Layer**: Input sanitization and environment checking
- **Strategy Engine**: Branch detection and worktree creation logic
- **Error Handling**: Comprehensive error recovery and cleanup
- **Completion System**: Zsh tab completion integration

**Function Dependencies:**

```text
gwt-create
├── _gwt_show_usage
├── _gwt_validate_branch_name
├── _gwt_check_git_repo
├── _gwt_check_not_in_worktree
├── _gwt_determine_branch_strategy
├── _gwt_resolve_target_directory
├── _gwt_create_worktree
└── _gwt_cleanup_failed_worktree
```

**Design Principles:**

- **Fail Fast**: Early validation prevents partial state
- **Clear Feedback**: Every operation provides status updates
- **Automatic Recovery**: Failed operations are cleaned up automatically
- **Extensibility**: Modular design enables feature additions

## Troubleshooting

### Common Issues

#### "Not a git repository" Error

**Problem**: Function called outside of a git repository.

**Solution**:

```bash
# Navigate to your git repository first
cd /path/to/your/git/repo
gwt-create feature/my-branch
```

#### "Cannot create worktree from inside another worktree"

**Problem**: Attempting to create worktree from within an existing worktree.

**Solution**:

```bash
# Navigate to main repository
cd $(git rev-parse --show-toplevel)
gwt-create feature/my-branch
```

#### Directory Already Exists

**Problem**: Target directory conflicts with existing file/folder.

**Solutions**:

```bash
# Use custom directory name
gwt-create existing-branch-name custom-directory

# Or remove the conflicting directory
rm -rf ../my-project-worktrees/conflicting-directory-name
gwt-create existing-branch-name
```

#### Insufficient Disk Space

**Problem**: Less than 100MB available for worktree creation.

**Solution**:

```bash
# Free up disk space or use different location
df -h  # Check available space
gwt-create feature/branch /path/with/more/space/branch-dir
```

#### Branch Already Checked Out

**Problem**: Branch is already active in another worktree.

**Solution**:

```bash
# List current worktrees
git worktree list

# Remove unused worktree if safe to do so
git worktree remove /path/to/unused/worktree

# Or create worktree for a different branch
gwt-create different-branch-name
```

### Performance Issues

**Large Repository Optimization:**

For repositories with many branches (>100), consider:

```bash
# Use specific branch names instead of relying on completion
gwt-create specific-branch-name

# Limit remote branch fetching
git config remote.origin.fetch "+refs/heads/main:refs/remotes/origin/main"
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Add to ~/.zshrc for debugging
export GWT_DEBUG=1
```

## Performance

### Benchmarks

**Operation Performance (tested on 2023 MacBook Pro M2)**:

| Repository Size | Branches | Creation Time | Navigation Time |
| --------------- | -------- | ------------- | --------------- |
| Small (< 100MB) | < 50     | ~0.5s         | ~0.1s           |
| Medium (< 1GB)  | < 200    | ~1.2s         | ~0.2s           |
| Large (< 5GB)   | < 500    | ~3.0s         | ~0.3s           |

**Memory Usage**: < 10MB peak during operation

**Disk Space**: Worktrees share object storage, minimal overhead

### Optimization Tips

1. **Use specific branch names** instead of wildcards
2. **Clean up unused worktrees** regularly with `git worktree prune`
3. **Limit remote tracking** for very large repositories
4. **Use SSD storage** for best performance

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history, feature additions, bug fixes, and upcoming releases.

**Current Version**: Unreleased (in development) - Full-featured git worktree management with organized structure and comprehensive layered testing.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

---

**Created by**: [Retso Huang](https://github.com/retsohuang)  
**Maintained by**: [Retso Huang](https://github.com/retsohuang)  
**Repository**: [git-worktree-zsh](https://github.com/retsohuang/git-worktree-zsh)  
**Issues**: [Report bugs and feature requests](https://github.com/retsohuang/git-worktree-zsh/issues)

⭐ **Star this project** if you find it useful!
