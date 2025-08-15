#!/bin/bash

# Test helper functions and common setup

# Common test environment setup
setup_git_repo() {
    local repo_name="${1:-test-repo}"
    
    git init "$repo_name"
    cd "$repo_name"
    
    git config user.name "Test User"
    git config user.email "test@example.com"
    git config init.defaultBranch main
    
    # Ensure we're on main branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "master" ]]; then
        git branch -m master main
    fi
    
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
}

# Load the main function file and ensure zsh functions work properly
load_git_worktree_functions() {
    if [[ -f "$ORIGINAL_DIR/git-worktree.zsh" ]]; then
        source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
    fi
}

# Run a zsh function with proper zsh context
# This is required when testing zsh-specific functionality (like glob expansion)
# that doesn't work in the bash environment where bats runs
# Usage: run_in_zsh <function_name> [args...]
run_in_zsh() {
    local func_name="$1"
    shift
    
    # Build the command string with proper argument handling
    local cmd="source '$ORIGINAL_DIR/git-worktree.zsh' && $func_name"
    
    # Add arguments if provided, with proper escaping
    if [[ $# -gt 0 ]]; then
        local escaped_args=()
        for arg in "$@"; do
            # Escape single quotes by replacing them with '\''
            local escaped_arg="${arg//\'/\'\\\'\'}"
            escaped_args+=("'$escaped_arg'")
        done
        cmd="$cmd ${escaped_args[*]}"
    fi
    
    # Execute in zsh
    zsh -c "$cmd"
}

# Clean up worktrees
cleanup_worktrees() {
    local worktree_pattern="${1:-*-worktrees}"
    
    # Remove any worktrees that were created during tests
    git worktree list --porcelain 2>/dev/null | grep "^worktree " | cut -d' ' -f2 | while read -r worktree; do
        if [[ "$worktree" =~ $worktree_pattern ]]; then
            git worktree remove "$worktree" --force 2>/dev/null || true
        fi
    done
    
    # Clean up any leftover directories
    if [[ -d "../$worktree_pattern" ]]; then
        rm -rf "../$worktree_pattern" 2>/dev/null || true
    fi
}