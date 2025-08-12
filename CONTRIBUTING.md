# Contributing to Git Worktree Zsh

We welcome contributions! This guide will help you get started with contributing to the Git Worktree Zsh project.

## Table of Contents

- [Quick Start](#quick-start)
- [Development Environment Setup](#development-environment-setup)
- [Testing Strategy](#testing-strategy)
- [Coding Standards](#coding-standards)
- [Submitting Contributions](#submitting-contributions)
- [Feature Protection Guidelines](#feature-protection-guidelines)
- [Getting Help](#getting-help)

## Quick Start

### 1. Fork and Clone the Repository

```bash
# Fork the repository on GitHub first, then clone your fork
git clone https://github.com/YOUR_GITHUB_USERNAME/git-worktree-zsh.git
cd git-worktree-zsh

# Or clone the main repository directly for read-only access
# git clone https://github.com/retsohuang/git-worktree-zsh.git
```

### 2. Set Up Development Environment

```bash
# Install bats-core for testing (macOS)
brew install bats-core

# Or on Ubuntu/Debian
sudo apt-get install bats

# Source the functions for testing
source ./git-worktree.zsh
```

### 3. Make Your Changes and Test

```bash
# Quick smoke tests during development
bats test/test_gwt_create.bats

# Comprehensive testing before submitting
./scripts/test-layered.sh

# Test specific layers
bats test/core/           # Must pass
bats test/unit/           # Must pass
bats test/integration/    # Should pass

# Validate zsh syntax
zsh -n git-worktree.zsh
```

### 4. Submit a Pull Request

- Follow our coding standards
- Include tests for new functionality
- Update documentation as needed

## Development Environment Setup

### Prerequisites

**Required:**
- **Git**: Version 2.5 or higher
- **Zsh**: Version 5.0 or higher
- **bats-core**: For running tests

**Optional but Recommended:**
- **shellcheck**: For shell script linting
- **markdownlint**: For documentation linting

### Installation Commands

```bash
# macOS (using Homebrew)
brew install git zsh bats-core shellcheck markdownlint-cli2

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git zsh bats shellcheck npm
npm install -g markdownlint-cli2

# Verify installations
git --version
zsh --version
bats --version
shellcheck --version
```

## Testing Strategy

### Layered Testing Architecture

We use a layered testing strategy with 35 tests across 4 categories:

#### Core Tests (9 tests - MUST pass)
Tests the main value proposition: organized worktree structure.

```bash
bats test/core/
```

**What they test:**
- Organized worktree structure creation
- Container directory auto-creation
- Multiple worktrees in same container
- Custom directory names in organized structure

#### Unit Tests (10 tests - MUST pass)
Tests individual functions in isolation.

```bash
bats test/unit/
```

**What they test:**
- Path resolution functions
- Branch name validation
- Directory sanitization
- Branch strategy determination

#### Integration Tests (7 tests - MUST pass for release)
Tests complete end-to-end workflows.

```bash
bats test/integration/
```

**What they test:**
- Complete feature development workflow
- Multiple parallel branches
- Error recovery scenarios
- Performance with multiple worktrees

#### Environment Tests (9 tests - failures allowed)
Tests platform and environment-specific features.

```bash
bats test/environment/
```

**What they test:**
- Zsh completion functions
- Platform compatibility
- Performance characteristics
- Git hooks compatibility

### Running Tests

```bash
# Development workflow
bats test/test_gwt_create.bats              # Quick smoke test (9 tests)
./scripts/test-layered.sh                   # Comprehensive testing (35 tests)

# Individual layers
bats test/core/                             # Core functionality
bats test/unit/                             # Unit tests
bats test/integration/                      # Integration tests
bats test/environment/                      # Environment tests

# Validation
zsh -n git-worktree.zsh                     # Syntax check
shellcheck git-worktree.zsh                # Linting (if available)

# Manual testing
markdownlint-cli2                           # Documentation formatting
source git-worktree.zsh && gwt-create --help  # Interactive testing
```

### Test Failure Guidelines

- **Core or Unit test failures**: ❌ STOP - Fix immediately
- **Integration test failures**: ⚠️ WARNING - Fix before release
- **Environment test failures**: ✅ OK - May continue, environment-specific

## Coding Standards

### Zsh Function Guidelines

1. **Use local variables** to avoid namespace pollution:
   ```zsh
   function my_function() {
       local var="value"
       # ...
   }
   ```

2. **Implement proper error checking**:
   ```zsh
   if ! command_that_might_fail; then
       echo "Error: Descriptive message" >&2
       return 1
   fi
   ```

3. **Use meaningful function names** with `_gwt_` prefix for internal functions:
   ```zsh
   function _gwt_validate_input() {
       # Internal helper function
   }
   ```

4. **Follow zsh parameter expansion patterns**:
   ```zsh
   # Good
   local sanitized="${branch_name//\//-}"
   
   # Avoid
   local sanitized=$(echo "$branch_name" | sed 's/\//-/g')
   ```

### Documentation Standards

1. **Function documentation**:
   ```zsh
   # Brief description of what the function does
   # Usage: function_name <required_param> [optional_param]
   function function_name() {
       # Implementation
   }
   ```

2. **Inline comments** for complex logic:
   ```zsh
   # CORE-FEATURE: This implements the organized structure
   # DO NOT REMOVE: This line creates the "{project-name}-worktrees" pattern
   local worktree_container="${parent_dir}/${project_name}-worktrees"
   ```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or fixing tests
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat: add branch name validation with helpful error messages
fix: handle directory conflicts in worktree creation
docs: update README with installation instructions
test: add integration tests for error recovery
```

## Submitting Contributions

### Before Submitting

1. **Run the full test suite**:
   ```bash
   ./scripts/test-layered.sh
   ```

2. **Validate code quality**:
   ```bash
   zsh -n git-worktree.zsh
   shellcheck git-worktree.zsh  # If available
   ```

3. **Update documentation** if needed:
   - README.md for user-facing changes
   - CLAUDE.md for development guidance
   - Inline code comments for complex logic

### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** with proper commits

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a pull request** with:
   - Clear description of changes
   - Reference to any related issues
   - Screenshots if UI changes
   - Test results confirmation

### Pull Request Review

Your PR will be reviewed for:
- **Functionality**: Does it work as intended?
- **Tests**: Are new features tested? Do existing tests pass?
- **Code Quality**: Does it follow our coding standards?
- **Documentation**: Is documentation updated appropriately?
- **Feature Protection**: Does it respect core functionality?

## Feature Protection Guidelines

### Critical Rules

1. **Never remove implemented features** for test convenience
2. **Organized folder structure** is core value proposition - must be preserved
3. **Test failures should lead to test fixes**, not feature removal
4. **Breaking changes require clear business justification**

### Protected Features

- **Organized Structure**: `{project-name}-worktrees/{branch-name}` pattern
- **Automatic Container Creation**: Worktree container directory creation
- **Branch Strategy Detection**: Intelligent local/remote/new branch handling
- **Error Recovery**: Cleanup on failed operations

### Code Markers

Look for these markers in code - they indicate protected functionality:
```zsh
# CORE-FEATURE: Brief description
# DO NOT REMOVE: Explanation of why this is critical
```

## Getting Help

### Resources

- **Issues**: [Report bugs and request features](https://github.com/retsohuang/git-worktree-zsh/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/retsohuang/git-worktree-zsh/discussions)
- **CLAUDE.md**: Development guidelines for AI assistants

### Common Questions

**Q: My tests are failing, should I modify the functionality?**
A: No! Fix the tests first. Core and unit test failures indicate bugs that need fixing, not features that need removing.

**Q: Can I simplify the organized structure for easier testing?**
A: No! The organized structure is the core value proposition. Tests should accommodate the feature, not the other way around.

**Q: How do I add a new test?**
A: Add tests to the appropriate layer:
- `test/core/` for core functionality
- `test/unit/` for individual functions
- `test/integration/` for workflows
- `test/environment/` for platform-specific features

**Q: My environment tests are failing, is that okay?**
A: Yes! Environment tests are allowed to fail due to platform differences. Focus on core, unit, and integration tests.

---

Thank you for contributing to Git Worktree Zsh! 🚀