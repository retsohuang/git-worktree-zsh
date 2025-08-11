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

# Load the main function file
load_git_worktree_functions() {
    if [[ -f "$ORIGINAL_DIR/git-worktree.zsh" ]]; then
        source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
    fi
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