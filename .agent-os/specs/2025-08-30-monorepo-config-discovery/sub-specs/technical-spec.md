# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-30-monorepo-config-discovery/spec.md

> Created: 2025-08-30
> Version: 1.0.0

## Technical Requirements

### Enhanced Discovery Algorithm

- Modify `_gwt_find_config_file()` function to collect all .gwt-config files from current working directory to git root
- Continue directory tree walking to collect complete configuration hierarchy rather than stopping at first match
- Return array of all found config file paths ordered from closest to git root
- Use `dirname` and path manipulation within zsh to walk directory hierarchy safely

### Configuration Merging Implementation

- Create new function `_gwt_merge_configs()` to handle .gitignore-like merging behavior
- Process collected config files from git root to current directory (reverse order for proper precedence)
- Implement include/exclude pattern resolution with closer configs overriding parent configs
- Handle exclusion patterns (`!`) with proper precedence across the merged configuration set
- Return final merged list of files/patterns to copy

### Search Path Implementation

- Start from `pwd` (current working directory) and check for .gwt-config
- Walk up using `dirname` until reaching git root (`git rev-parse --show-toplevel`)
- Collect all found .gwt-config files rather than stopping at first match
- Implement loop protection to prevent infinite cycles in edge cases
- Handle symlinks and mounted filesystems using standard zsh path resolution

### Performance Optimization

- Cache git root determination to avoid repeated `git rev-parse` calls
- Limit maximum directory depth traversal to prevent performance issues in deep structures
- Use efficient string operations for path manipulation and config merging
- Optimize config parsing to avoid redundant file reads

### Enhanced Logging and Error Handling

- Add debug output showing all config file paths found during hierarchy traversal
- Log the final merged configuration result when `GWT_DEBUG=1` is set
- Show precedence order and which patterns came from which config files
- Handle permission denied errors gracefully during directory access
- Provide clear error messages when no config files found in entire hierarchy

### Backward Compatibility

- Preserve existing function interface and return values
- Maintain identical behavior for current directory and git root scenarios
- Ensure no performance regression for existing single-repo use cases
- Keep all existing function dependencies and calling patterns intact

### Implementation Details

- Update function documentation to reflect new configuration merging behavior
- Add comprehensive test coverage for monorepo directory structures and config inheritance
- Ensure proper handling of relative path resolution from multiple config file locations
- Maintain zsh compatibility across versions 5.0+ as per tech stack requirements
- Create example scenarios demonstrating .gitignore-like precedence rules
- Add integration tests for exclusion pattern handling across merged configurations