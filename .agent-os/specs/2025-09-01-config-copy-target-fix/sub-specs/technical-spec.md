# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-01-config-copy-target-fix/spec.md

> Created: 2025-09-01
> Version: 1.0.0

## Technical Requirements

### Bug Fix 1: Incorrect Target Directory Calculation

**Problem**: Config files are being copied to wrong target directories when `.gwt-config` is located in subdirectories.

**Current Behavior**:
```bash
# Config at: project/subdir/.gwt-config
# File: project/subdir/config.txt
# Current target: worktree/config.txt (WRONG)
# Expected target: worktree/subdir/config.txt
```

**Solution Requirements**:
- Fix target path calculation in `_gwt_copy_config_file()` function
- Preserve relative directory structure from config file location
- Calculate target based on file's position relative to `.gwt-config` directory

### Bug Fix 2: Duplicate Copy Operation Logging

**Problem**: Copy operations generate duplicate log messages for the same file.

**Current Behavior**:
```
Copying config.txt to worktree
Copying config.txt to worktree
```

**Solution Requirements**:
- Deduplicate logging in copy operations
- Ensure single log message per unique file copy
- Maintain clear visibility of copy operations

### Backward Compatibility Requirements

- All existing `.gwt-config` configurations must continue to work
- No breaking changes to config file format
- Maintain existing API for config processing functions

## Approach

### Target Directory Fix Implementation

**Function**: `_gwt_copy_config_file()`

**Current Logic**:
```bash
target_file="$worktree_path/$(basename "$source_file")"
```

**Fixed Logic**:
```bash
# Calculate relative path from config directory to source file
config_dir=$(dirname "$config_file")
relative_path=$(realpath --relative-to="$config_dir" "$source_file")
target_file="$worktree_path/$relative_path"
```

**Edge Cases to Handle**:
1. Config file at repository root
2. Source files in parent directories relative to config
3. Symlinks in directory structure
4. Special characters in file paths

### Logging Deduplication Implementation

**Approach 1: Track Copied Files**
```bash
# Global associative array to track copied files
typeset -gA _gwt_copied_files

_gwt_copy_config_file() {
    local file_key="$source_file->$target_file"
    if [[ -z "${_gwt_copied_files[$file_key]}" ]]; then
        # Perform copy and log
        _gwt_copied_files[$file_key]=1
        echo "Copying $(basename "$source_file") to worktree"
    fi
}
```

**Approach 2: Single Copy Pass**
```bash
# Collect all files first, then copy with single log per file
_gwt_process_config_files() {
    local -A unique_copies
    # Build unique copy operations
    # Execute with single log per operation
}
```

### Directory Structure Preservation

**Implementation Strategy**:
1. Create target directories if they don't exist
2. Maintain directory permissions from source
3. Handle nested directory structures

```bash
_gwt_ensure_target_directory() {
    local target_file="$1"
    local target_dir=$(dirname "$target_file")
    
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        echo "Created directory structure: $target_dir"
    fi
}
```

## External Dependencies

### System Commands Required
- `realpath` - For calculating relative paths
- `dirname` - For directory path extraction  
- `basename` - For filename extraction
- `mkdir -p` - For recursive directory creation

### Zsh Features Utilized
- Associative arrays for deduplication tracking
- Parameter expansion for path manipulation
- Conditional expressions for file system checks

### Error Handling Requirements
- Graceful handling of missing `realpath` command
- Fallback path calculation methods
- Clear error messages for permission issues
- Validation of calculated paths before operations

## Testing Strategy

### Unit Tests
- Test `_gwt_copy_config_file()` with various directory structures
- Test path calculation edge cases
- Test logging deduplication logic

### Integration Tests  
- Test complete config copying workflow
- Test with configs in various subdirectory locations
- Verify preserved directory structure in worktrees

### Regression Tests
- Ensure existing configurations continue working
- Test backward compatibility scenarios
- Validate no breaking changes to existing workflows