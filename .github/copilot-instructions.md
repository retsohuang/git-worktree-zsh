# Copilot Instructions for git-worktree-zsh

This repository contains zsh functions for creating and managing git worktrees with organized folder structure. These instructions will help coding agents work efficiently with this project.

## Repository Overview

> **📋 Complete project details**: See [.agent-os/product/mission.md](.agent-os/product/mission.md) for product mission, users, and key features
> 
> **🔧 Technical specifications**: See [.agent-os/product/tech-stack.md](.agent-os/product/tech-stack.md) for complete technology stack and platform support

**Project Type**: Shell function suite for git worktree management  
**Main Language**: Zsh shell scripting  
**Target Runtime**: Zsh 5.0+, Git 2.5+, Unix-like systems (macOS/Linux/WSL)

**Core Value Proposition**: Creates git worktrees in organized `{project-name}-worktrees/{branch-name}` directory structure instead of scattered directories.

**Main Function**: `gwt-create <branch-name> [target-directory]`

## Build and Validation Commands

> **📖 Complete development workflow**: See [CLAUDE.md](CLAUDE.md) for comprehensive development commands, testing strategy, and architecture details

### Prerequisites Installation
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y zsh bats git

# macOS (if not available)
brew install zsh bats-core git

# Verify versions
zsh --version    # Need 5.0+
git --version    # Need 2.5+
bats --version   # For testing
```

### No Build Step Required
**IMPORTANT**: This is a shell function project with no compilation step. Functions are sourced directly.

### Validation Workflow (Always follow this order)

#### 1. Syntax Validation (Required)
```bash
# ALWAYS run this first - catches zsh syntax errors
zsh -n git-worktree.zsh
# Success: no output, exit code 0
# Failure: syntax error message, exit code 1
```

#### 2. Manual Function Testing (Recommended)
```bash
# Source functions and test basic operation
source ./git-worktree.zsh
gwt-create --help
# Should show usage information without errors
```

#### 3. Quick Smoke Tests (Development)
```bash
# Fast validation during development (9 tests, ~10 seconds)
bats test/test_gwt_create.bats
# Expected: 8-9 tests pass (1 meta-test may fail, this is acceptable)
```

#### 4. Comprehensive Testing (Before Submission)
```bash
# Full validation (35 tests across 4 layers, ~60 seconds)
./scripts/test-layered.sh

# CRITICAL: Core and Unit tests MUST pass
# Integration tests SHOULD pass for release
# Environment tests MAY fail (platform-specific, acceptable)
```

### Individual Test Layers
```bash
# Core functionality (9 tests - MUST pass)
bats test/core/

# Unit tests (10 tests - MUST pass) 
bats test/unit/

# Integration workflows (7 tests - SHOULD pass)
bats test/integration/

# Environment/platform tests (9 tests - failures OK)
bats test/environment/
```

### Documentation Validation
```bash
# Install if needed
npm install -g markdownlint-cli2

# Lint documentation
markdownlint-cli2
# Uses .markdownlint-cli2.jsonc config
```

## Known Issues and Workarounds

> **⚠️ Complete issue documentation**: See [CLAUDE.md](CLAUDE.md) for detailed known issues, workarounds, and feature protection rules

### Critical Guidelines Summary
- **Fix Tests, Not Features**: When tests fail, prioritize fixing tests over removing functionality
- **Feature Protection**: Never remove organized `{project-name}-worktrees/{branch-name}` structure
- **Test Failures**: Environment test failures are acceptable; core/unit test failures require immediate attention

### Git Default Branch Name Issues
**Problem**: Unit tests may fail with "pathspec 'main' did not match any file(s) known to git"  
**Cause**: Git defaults to 'master' branch, tests expect 'main'  
**Workaround**: This is environment-specific and acceptable - focus on core functionality  
**Fix Tests Not Code**: If tests fail, update test expectations, don't modify functions

### Test Environment Sensitivity
**Expected Failures**: Environment tests may fail due to:
- Git configuration differences
- Platform-specific filesystem behavior  
- Missing optional tools (completion, performance tools)
**Action**: Continue development - these failures don't indicate functional problems

### Timing Issues in CI
**Problem**: Test timeouts in limited CI environments  
**Workaround**: Tests include generous timeouts, but complex git operations may still timeout  
**Solution**: Re-run tests or use local environment for validation

## Project Layout and Architecture

> **🏗️ Complete architecture details**: See [CLAUDE.md](CLAUDE.md) for function design patterns, architecture notes, and implementation details
> 
> **📋 Product decisions**: See [.agent-os/product/decisions.md](.agent-os/product/decisions.md) for architectural decisions and rationale

### Root Directory Files
```
git-worktree.zsh              # Main function suite (26KB)
git-worktree.plugin.zsh       # Oh My Zsh plugin wrapper
README.md                     # User documentation (15KB)
CLAUDE.md                     # AI assistant guidance (5KB)
CONTRIBUTING.md               # Developer guidelines (9KB)
CHANGELOG.md                  # Version history
LICENSE.md                    # MIT license
.markdownlint-cli2.jsonc      # Markdown linting config
.gitignore                    # Git ignore patterns
```

### Key Directories
```
.github/workflows/            # GitHub Actions (Claude AI integration)
scripts/                      # Test runner scripts
  test-layered.sh            # Comprehensive test runner
test/                        # Test suite (4-layer strategy)
  test_gwt_create.bats       # Quick smoke tests
  core/                      # Core functionality tests (9)
  unit/                      # Individual function tests (10)
  integration/               # Workflow tests (7)
  environment/               # Platform-specific tests (9)
  test_helper.bash           # Test utilities
.agent-os/                   # Agent OS specifications (ignore)
```

### Main Function Architecture
```
git-worktree.zsh contains:
├── gwt-create()              # Main public function
├── _gwt_show_usage()         # Help/usage display
├── _gwt_validate_*()         # Input validation functions
├── _gwt_check_*()            # Environment checking
├── _gwt_determine_*()        # Branch strategy logic
├── _gwt_resolve_*()          # Path resolution
├── _gwt_create_worktree()    # Core worktree creation
└── _gwt_cleanup_*()          # Error cleanup
```

## Critical Feature Protection Rules

> **🛡️ Complete protection guidelines**: See [CLAUDE.md](CLAUDE.md) for comprehensive feature protection rules and test fix strategies

### NEVER REMOVE These Features
1. **Organized Structure**: `{project-name}-worktrees/{branch-name}` pattern
2. **Container Auto-Creation**: Automatic worktree container directory creation
3. **Branch Strategy Detection**: Local/remote/new branch handling logic

### When Tests Fail - Priority Order
1. **Core test failures**: STOP - Fix immediately, core functionality broken
2. **Unit test failures**: STOP - Fix immediately, functions broken  
3. **Integration failures**: WARNING - Fix before release, workflows affected
4. **Environment failures**: OK - Continue, platform-specific issues

### Code Change Guidelines
- **Fix Tests, Not Features**: When tests fail, prioritize fixing tests over removing functionality
- **Preserve Core Value**: Organized structure is the main value proposition
- **Local Variables**: Use `local` for all function variables
- **Error Checking**: All commands should have error handling
- **Function Naming**: Internal functions use `_gwt_` prefix

## Validation Steps for Code Changes

> **✅ Complete validation workflow**: See [CLAUDE.md](CLAUDE.md) for detailed validation steps and testing commands

### Quick Reference
### Quick Reference
1. Run syntax check: `zsh -n git-worktree.zsh`
2. Test manual sourcing: `source ./git-worktree.zsh && gwt-create --help`
3. Run quick tests: `bats test/test_gwt_create.bats`
4. Run full test suite: `./scripts/test-layered.sh`

### Acceptance Criteria
- ✅ Syntax check passes
- ✅ Manual function loading works
- ✅ Core tests pass (9/9)
- ✅ Unit tests pass (10/10) or have documented environment reasons for failure
- ✅ Integration tests pass (7/7) or documented issues
- ⚠️ Environment tests may fail (acceptable)

## Dependencies and Environment

> **🔧 Complete tech stack**: See [.agent-os/product/tech-stack.md](.agent-os/product/tech-stack.md) for full technical specifications and platform support

### Required Runtime Dependencies
- **git**: 2.5+ (for worktree support)
- **zsh**: 5.0+ (target shell)

### Development Dependencies  
- **bats-core**: Test framework
- **markdownlint-cli2**: Documentation linting (optional)

### Platform Support
- ✅ **Primary**: macOS 10.15+, Ubuntu 20.04+
- ✅ **Secondary**: Windows WSL2, CentOS 8+

## Time Requirements for Commands

| Command | Duration | Notes |
|---------|----------|-------|
| `zsh -n git-worktree.zsh` | <1s | Syntax check |
| `bats test/test_gwt_create.bats` | ~3s | Quick smoke tests |
| `./scripts/test-layered.sh` | ~10s | Full test suite |
| `bats test/core/` | ~2s | Core functionality |
| `bats test/unit/` | ~3s | Unit tests (may fail on env issues) |
| `bats test/integration/` | ~2s | Integration tests |
| `bats test/environment/` | ~3s | Environment tests |

## Single Source of Truth References

This file provides essential onboarding guidance for coding agents. For detailed information, always refer to these authoritative sources:

- **[CLAUDE.md](CLAUDE.md)**: Complete development workflow, testing strategy, architecture details, and feature protection rules
- **[.agent-os/product/mission.md](.agent-os/product/mission.md)**: Product mission, users, problems, and key features  
- **[.agent-os/product/tech-stack.md](.agent-os/product/tech-stack.md)**: Full technical stack and platform requirements
- **[.agent-os/product/decisions.md](.agent-os/product/decisions.md)**: Architectural decisions and their rationale

## Trust These Instructions

These instructions have been validated through comprehensive repository exploration and testing. **Only perform additional searching if:**
- Information here is incomplete or contradictory
- You encounter errors not documented in the known issues
- You need to understand specific implementation details not covered

**Start with these commands and workflows** - they are known to work correctly in the project environment.