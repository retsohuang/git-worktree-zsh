#!/usr/bin/env bats

# Integration tests for complete workflows
# These test end-to-end functionality

load '../test_helper'

setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    
    cd "$TEST_TEMP_DIR"
    git init test-repo
    cd test-repo
    
    git config user.name "Test User"
    git config user.email "test@example.com"
    git config init.defaultBranch main
    
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "master" ]]; then
        git branch -m master main
    fi
    
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

@test "INTEGRATION: Complete feature development workflow" {
    # Create feature branch worktree
    run gwt-create feature/user-authentication
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/feature-user-authentication" ]
    
    # Should automatically navigate to the worktree
    # Verify we can work in the worktree
    cd "../test-repo-worktrees/feature-user-authentication"
    echo "feature code" > feature.js
    git add feature.js
    git commit -m "Add feature code"
    
    # Verify the branch exists and has the commit
    [ "$(git branch --show-current)" = "feature/user-authentication" ]
    [ -f "feature.js" ]
}

@test "INTEGRATION: Multiple parallel branches" {
    # Create multiple worktrees (need to return to main repo between each)
    run gwt-create feature/frontend
    [ "$status" -eq 0 ]
    
    cd "$TEST_TEMP_DIR/test-repo"  # Return to main repo
    run gwt-create feature/backend
    [ "$status" -eq 0 ]
    
    cd "$TEST_TEMP_DIR/test-repo"  # Return to main repo
    run gwt-create hotfix/critical-bug
    [ "$status" -eq 0 ]
    
    # All should exist in organized structure
    [ -d "../test-repo-worktrees/feature-frontend" ]
    [ -d "../test-repo-worktrees/feature-backend" ]  
    [ -d "../test-repo-worktrees/hotfix-critical-bug" ]
    
    # All should be functional git repositories
    cd "../test-repo-worktrees/feature-frontend"
    [ "$(git branch --show-current)" = "feature/frontend" ]
    
    cd "$TEST_TEMP_DIR/test-repo-worktrees/feature-backend"
    [ "$(git branch --show-current)" = "feature/backend" ]
    
    cd "$TEST_TEMP_DIR/test-repo-worktrees/hotfix-critical-bug"
    [ "$(git branch --show-current)" = "hotfix/critical-bug" ]
}

@test "INTEGRATION: Error recovery maintains clean state" {
    # Create a conflicting directory with content (so cleanup won't remove it)
    mkdir -p "../test-repo-worktrees"
    mkdir -p "../test-repo-worktrees/existing-conflict"
    echo "existing content" > "../test-repo-worktrees/existing-conflict/file.txt"
    
    # Attempt to create worktree with same name should fail cleanly
    run gwt-create existing-conflict
    [ "$status" -eq 1 ]
    
    # Should not leave any corrupted state (directory should still exist with original content)
    [ -d "../test-repo-worktrees/existing-conflict" ]
    [ -f "../test-repo-worktrees/existing-conflict/file.txt" ]
    [ ! -f "../test-repo-worktrees/existing-conflict/.git" ]
    
    # Should be able to create with different name
    run gwt-create existing-conflict conflict-resolved
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/conflict-resolved" ]
}

@test "INTEGRATION: Branch name sanitization with custom directory" {
    # Test complete workflow with complex branch names
    run gwt-create "feature/user-auth/oauth2.0" "auth-system"
    [ "$status" -eq 0 ]
    
    # Should create with custom directory name in organized structure
    [ -d "../test-repo-worktrees/auth-system" ]
    [ ! -d "../auth-system" ]
    
    # Verify correct branch name is preserved
    cd "../test-repo-worktrees/auth-system"
    [ "$(git branch --show-current)" = "feature/user-auth/oauth2.0" ]
}

@test "INTEGRATION: Dry run accuracy validation" {
    # Dry run should show accurate preview
    run gwt-create --dry-run "feature/preview-test"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-repo-worktrees/feature-preview-test" ]]
    [[ "$output" =~ "Strategy: create-new" ]]
    
    # Should not create anything
    [ ! -d "../test-repo-worktrees" ]
    
    # Actual execution should match preview
    run gwt-create "feature/preview-test" 
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/feature-preview-test" ]
}

@test "INTEGRATION: Performance with multiple worktrees" {
    # Create several worktrees to test performance
    local worktrees=("feature/perf-1" "feature/perf-2" "feature/perf-3")
    
    for worktree in "${worktrees[@]}"; do
        local start_time=$(date +%s)
        run gwt-create "$worktree"
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        [ "$status" -eq 0 ]
        [ "$duration" -lt 5 ]  # Should complete quickly
    done
    
    # All should exist in organized structure
    for worktree in "${worktrees[@]}"; do
        local sanitized="${worktree//\//-}"
        [ -d "../test-repo-worktrees/$sanitized" ]
    done
}

@test "INTEGRATION: Worktree from subdirectory" {
    # Create subdirectory structure
    mkdir -p src/components
    cd src/components
    
    # Should work from subdirectory
    run gwt-create "feature/subdir-test"
    [ "$status" -eq 0 ]
    
    # Return to repo root to check
    cd "$TEST_TEMP_DIR/test-repo"
    
    # Should create in correct location relative to repo root
    [ -d "../test-repo-worktrees/feature-subdir-test" ]
}