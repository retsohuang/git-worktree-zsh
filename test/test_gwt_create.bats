#!/usr/bin/env bats

# Main test suite for gwt-create function
# This provides basic smoke tests for quick development feedback
# For comprehensive testing, use the layered test strategy: ./scripts/test-layered.sh

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

# Essential functionality tests
@test "gwt-create function exists and shows help" {
    run gwt-create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "gwt-create" ]]
}

@test "gwt-create creates organized worktree structure" {
    run gwt-create feature/test-organized
    [ "$status" -eq 0 ]
    
    # Verify organized structure
    [ -d "../test-repo-worktrees/feature-test-organized" ]
    [ ! -d "../feature-test-organized" ]
    
    # Verify it's a functional worktree
    cd "../test-repo-worktrees/feature-test-organized"
    [ "$(git branch --show-current)" = "feature/test-organized" ]
}

@test "gwt-create handles custom directory names in organized structure" {
    run gwt-create feature/complex-name simple-name
    [ "$status" -eq 0 ]
    
    # Should be in organized structure with custom name
    [ -d "../test-repo-worktrees/simple-name" ]
    [ ! -d "../simple-name" ]
    
    # Verify branch name is preserved
    cd "../test-repo-worktrees/simple-name"
    [ "$(git branch --show-current)" = "feature/complex-name" ]
}

@test "gwt-create dry-run shows organized structure" {
    run gwt-create --dry-run feature/dry-test
    [ "$status" -eq 0 ]
    
    # Should show organized path
    [[ "$output" =~ "test-repo-worktrees/feature-dry-test" ]]
    
    # Should not create anything
    [ ! -d "../test-repo-worktrees" ]
}

@test "gwt-create validates branch names" {
    # Invalid branch names should be rejected
    run gwt-create "invalid branch name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Valid branch names should pass validation
    run gwt-create --dry-run feature/valid-branch
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Invalid branch name" ]]
}

@test "gwt-create detects git repository requirements" {
    # Should fail outside git repository
    cd "$TEST_TEMP_DIR"
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not a git repository" ]]
}

@test "gwt-create handles directory conflicts gracefully" {
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

@test "gwt-create creates multiple worktrees in same container" {
    # Create first worktree
    run gwt-create feature/first
    [ "$status" -eq 0 ]
    
    # Go back to main repo for second worktree creation
    cd "$TEST_TEMP_DIR/test-repo"
    
    # Create second worktree
    run gwt-create feature/second
    [ "$status" -eq 0 ]
    
    # Both should exist in same container
    [ -d "../test-repo-worktrees/feature-first" ]
    [ -d "../test-repo-worktrees/feature-second" ]
    
    # Both should be functional
    cd "../test-repo-worktrees/feature-first"
    [ "$(git branch --show-current)" = "feature/first" ]
    
    cd "$TEST_TEMP_DIR/test-repo-worktrees/feature-second"
    [ "$(git branch --show-current)" = "feature/second" ]
}

# Run layered tests if available
@test "Layered test strategy validates core functionality" {
    if [ -x "$ORIGINAL_DIR/scripts/test-layered.sh" ]; then
        cd "$ORIGINAL_DIR"
        run "$ORIGINAL_DIR/scripts/test-layered.sh"
        # Core and unit tests must pass
        [[ "$output" =~ "CORE TESTS PASSED" ]]
        [[ "$output" =~ "UNIT TESTS PASSED" ]]
        # Overall result should indicate core functionality works (script returns 0 for core functionality OK)
        [ "$status" -eq 0 ]
    else
        skip "Layered test script not available"
    fi
}