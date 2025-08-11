#!/usr/bin/env bats

# Unit tests for path resolution functions
# These test individual functions in isolation

load '../test_helper'

setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    
    cd "$TEST_TEMP_DIR"
    git init test-repo
    cd test-repo
    
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "test" > README.md
    git add README.md
    git commit -m "test"
    
    source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

@test "UNIT: _gwt_resolve_target_directory returns organized path" {
    run _gwt_resolve_target_directory "feature/test-branch"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /test-repo-worktrees/feature-test-branch$ ]]
}

@test "UNIT: _gwt_resolve_target_directory handles custom target" {
    run _gwt_resolve_target_directory "test-branch" "custom-dir"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /test-repo-worktrees/custom-dir$ ]]
}

@test "UNIT: _gwt_resolve_target_directory handles relative paths" {
    run _gwt_resolve_target_directory "test-branch" "../custom-dir"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /test-repo-worktrees/custom-dir$ ]]
}

@test "UNIT: _gwt_sanitize_directory_name handles slashes" {
    run _gwt_sanitize_directory_name "feature/test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "feature-test-branch" ]
}

@test "UNIT: _gwt_validate_filesystem_access validates container parent" {
    # This should pass for normal directories
    run _gwt_validate_filesystem_access "../test-repo-worktrees/some-branch"
    [ "$status" -eq 0 ]
}

@test "UNIT: _gwt_branch_exists_locally detects existing branches" {
    # Create a test branch
    git checkout -b test-existing-branch
    git checkout main
    
    # Should detect existing branch
    run _gwt_branch_exists_locally test-existing-branch
    [ "$status" -eq 0 ]
    
    # Should not detect non-existing branch
    run _gwt_branch_exists_locally non-existing-branch
    [ "$status" -eq 1 ]
    
    # Cleanup
    git branch -D test-existing-branch
}

@test "UNIT: _gwt_determine_branch_strategy returns correct strategy" {
    # New branch should return create-new
    run _gwt_determine_branch_strategy new-branch-name
    [ "$status" -eq 0 ]
    [ "$output" = "create-new" ]
    
    # Existing local branch should return checkout-local
    git checkout -b local-test-branch
    git checkout main
    
    run _gwt_determine_branch_strategy local-test-branch
    [ "$status" -eq 0 ]
    [ "$output" = "checkout-local" ]
    
    # Cleanup
    git branch -D local-test-branch
}

@test "UNIT: _gwt_check_directory_conflict detects conflicts" {
    # Non-existing directory should pass
    run _gwt_check_directory_conflict "$TEST_TEMP_DIR/non-existing-dir"
    [ "$status" -eq 0 ]
    
    # Existing directory should fail
    local test_dir="$TEST_TEMP_DIR/existing-dir"
    mkdir -p "$test_dir"
    
    run _gwt_check_directory_conflict "$test_dir"
    [ "$status" -eq 1 ]
    
    # Existing file should fail
    local test_file="$TEST_TEMP_DIR/existing-file"
    echo "content" > "$test_file"
    
    run _gwt_check_directory_conflict "$test_file"
    [ "$status" -eq 1 ]
}

@test "UNIT: _gwt_validate_branch_name comprehensive validation" {
    # Valid branch names should pass
    run _gwt_validate_branch_name "feature/valid-branch"
    [ "$status" -eq 0 ]
    
    run _gwt_validate_branch_name "bugfix-123"
    [ "$status" -eq 0 ]
    
    run _gwt_validate_branch_name "v1.2.3"
    [ "$status" -eq 0 ]
    
    # Invalid branch names should fail
    run _gwt_validate_branch_name ""
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name "invalid branch name"
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name "-invalid"
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name ".invalid"
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name "invalid."
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name "branch..name"
    [ "$status" -eq 1 ]
    
    run _gwt_validate_branch_name "@"
    [ "$status" -eq 1 ]
}

@test "UNIT: _gwt_sanitize_directory_name handles various cases" {
    # Multiple slashes
    run _gwt_sanitize_directory_name "feature/user/auth/system"
    [ "$status" -eq 0 ]
    [ "$output" = "feature-user-auth-system" ]
    
    # Leading and trailing slashes
    run _gwt_sanitize_directory_name "/feature/auth/"
    [ "$status" -eq 0 ]
    [ "$output" = "feature-auth" ]
    
    # Empty input should fail
    run _gwt_sanitize_directory_name ""
    [ "$status" -eq 1 ]
    
    # Only slashes should return fallback
    run _gwt_sanitize_directory_name "///"
    [ "$status" -eq 0 ]
    [ "$output" = "branch" ]
}