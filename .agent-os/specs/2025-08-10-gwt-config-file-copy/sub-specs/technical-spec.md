# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-10-gwt-config-file-copy/spec.md

> Created: 2025-08-10
> Version: 1.0.0

## Technical Requirements

### Configuration Storage
- Use a simple configuration file `.gwt-config` in the git repository root
- Support both file paths and directory paths with glob patterns
- Allow comments in configuration file using `#` prefix
- Default configuration should include common development files

### Configuration File Format
- Plain text file with one entry per line
- Support for absolute and relative paths (relative to repo root)
- Support for glob patterns (*.md, .vscode/*, etc.)
- Support for exclusion patterns using `!` prefix

### Implementation Details
- Modify existing gwt-create function to check for .gwt-config file
- Use zsh built-in file operations for copying
- Implement recursive copying for directories
- Preserve file permissions and timestamps when copying
- Skip copying if source files don't exist (no error)

### Error Handling
- Continue worktree creation even if file copying fails
- Log copy failures but don't exit with error
- Provide clear messages for permission issues
- Handle symlinks by copying the target content

### Configuration Discovery
- Look for .gwt-config in current directory first
- Fall back to git repository root if not found locally
- If no config file exists, skip file copying (backward compatibility)

### Default Configuration
- Provide example .gwt-config with common development files:
  - .claude      # Claude AI configuration file
  - .agent-os/   # Agent OS configuration and specs directory
  - CLAUDE.md    # Project documentation for Claude
  - .vscode/     # VS Code editor settings
  - .idea/       # JetBrains IDE (e.g., PyCharm, IntelliJ) settings

## Approach

### Configuration File Processing
1. Read configuration file line by line
2. Skip empty lines and comments (lines starting with #)
3. Process glob patterns using zsh's built-in glob expansion
4. Handle exclusion patterns by filtering out matched files

### File Copying Strategy
1. For each configuration entry:
   - Resolve glob patterns to actual file/directory paths
   - Check if source exists in the main worktree
   - Copy to the new worktree maintaining directory structure
   - Log success/failure for each operation

### Integration with gwt-create
1. After successful worktree creation
2. Before any other setup operations
3. Read configuration and copy files
4. Continue with normal worktree setup regardless of copy results

## External Dependencies

### zsh Built-ins
- `cp` command with recursive and preserve options
- Glob pattern expansion
- File test operations (`[[ -f ]]`, `[[ -d ]]`)
- String manipulation for comment filtering

### Git Integration  
- `git rev-parse --show-toplevel` to find repository root
- Existing git worktree functionality remains unchanged