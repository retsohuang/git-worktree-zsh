#!/usr/bin/env bats

# Core functionality tests for organized worktree structure
# These tests MUST pass - they verify the core value proposition

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
    
    # Rename the default branch to main if it's master
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "master" ]]; then
        git branch -m master main
    fi
    
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Source the main function
    source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

# CRITICAL TESTS - These define the core value proposition

@test "CORE: Organized structure - worktree created in project-worktrees directory" {
    run gwt-create feature/test-organized
    [ "$status" -eq 0 ]
    
    # Verify organized structure: ../test-repo-worktrees/feature-test-organized
    [ -d "../test-repo-worktrees/feature-test-organized" ]
    
    # Verify it's NOT in the old flat structure
    [ ! -d "../feature-test-organized" ]
}

@test "CORE: Container directory auto-creation" {
    # Container should not exist initially
    [ ! -d "../test-repo-worktrees" ]
    
    run gwt-create feature/auto-create-container
    [ "$status" -eq 0 ]
    
    # Container should be created automatically
    [ -d "../test-repo-worktrees" ]
    [ -d "../test-repo-worktrees/feature-auto-create-container" ]
}

@test "CORE: Multiple worktrees in same container" {
    run gwt-create feature/first-branch
    [ "$status" -eq 0 ]
    
    run gwt-create feature/second-branch  
    [ "$status" -eq 0 ]
    
    # Both should exist in the same container
    [ -d "../test-repo-worktrees/feature-first-branch" ]
    [ -d "../test-repo-worktrees/feature-second-branch" ]
    
    # Verify they're both functional worktrees
    [ -f "../test-repo-worktrees/feature-first-branch/.git" ]
    [ -f "../test-repo-worktrees/feature-second-branch/.git" ]
}

@test "CORE: Custom directory name still uses organized structure" {
    run gwt-create feature/complex-name simple-name
    [ "$status" -eq 0 ]
    
    # Should be in organized structure with custom name
    [ -d "../test-repo-worktrees/simple-name" ]
    [ ! -d "../simple-name" ]
}

@test "CORE: Dry run shows organized structure path" {
    run gwt-create --dry-run feature/dry-run-test
    [ "$status" -eq 0 ]
    
    # Output should show the organized path structure
    [[ "$output" =~ test-repo-worktrees/feature-dry-run-test ]]
}

@test "CORE: Function exists and shows help" {
    run gwt-create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "gwt-create" ]]
}

@test "CORE: Basic branch name validation" {
    # Invalid branch names should be rejected
    run gwt-create "invalid branch name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Valid branch names should pass validation
    run gwt-create --dry-run feature/valid-branch
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Invalid branch name" ]]
}

@test "CORE: Git repository requirement" {
    # Should fail outside git repository
    cd "$TEST_TEMP_DIR"
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not a git repository" ]]
}

@test "CORE: Directory conflict handling" {
    # Create conflicting directory
    mkdir -p "../test-repo-worktrees/conflict-test"
    
    # Should fail with helpful error
    run gwt-create conflict-test
    [ "$status" -eq 1 ]
    [[ "$output" =~ "already exists" ]]
    
    # Should succeed with different name
    run gwt-create conflict-test resolved-conflict
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/resolved-conflict" ]
}