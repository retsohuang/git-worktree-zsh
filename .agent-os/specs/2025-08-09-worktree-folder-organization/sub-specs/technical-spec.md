# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-09-worktree-folder-organization/spec.md

> Created: 2025-08-09
> Version: 1.0.0

## Technical Requirements

### Current Behavior
The existing `gwt-create` command creates worktrees as sibling directories to the main project:
```
parent-directory/
├── my-project/          # main git repository
├── my-project-feature/  # worktree for feature branch
└── my-project-hotfix/   # worktree for hotfix branch
```

### New Behavior
The enhanced command should create worktrees in an organized subfolder:
```
parent-directory/
├── my-project/                    # main git repository
└── my-project-worktrees/          # worktree container directory
    ├── feature-branch/            # worktree for feature branch
    └── hotfix-branch/             # worktree for hotfix branch
```

### Implementation Details

1. **Path Resolution**: Extract the current project directory name using `basename $(git rev-parse --show-toplevel)`
2. **Parent Directory**: Get the parent directory of the current project
3. **Worktree Container**: Create "{project-name}-worktrees" directory in the parent
4. **Directory Creation**: Use `mkdir -p` to ensure the worktree container exists
5. **Git Worktree Command**: Execute `git worktree add` with the new organized path

### Function Modifications

Update the `gwt-create` function to:
- Calculate the organized worktree path
- Create the worktree container directory if needed
- Pass the new path to the git worktree add command
- Update any path-related error messages or feedback

## Approach

### Path Construction Logic
```zsh
# Get current project info
local project_root=$(git rev-parse --show-toplevel)
local project_name=$(basename "$project_root")
local parent_dir=$(dirname "$project_root")

# Construct organized path
local worktree_container="${parent_dir}/${project_name}-worktrees"
local worktree_path="${worktree_container}/${branch_name}"
```

### Error Handling
- Check if git repository is valid before proceeding
- Verify parent directory is writable
- Handle mkdir failures with appropriate error messages
- Maintain existing branch validation and conflict detection

### Backward Compatibility
- No changes to existing worktrees (they remain functional)
- No configuration migration required
- Existing gwt-* commands continue to work with old worktree locations

## External Dependencies

- Git worktree functionality (existing dependency)
- Standard zsh built-ins: `basename`, `dirname`, `mkdir`
- File system write permissions to parent directory