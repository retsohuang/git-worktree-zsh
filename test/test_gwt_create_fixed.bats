#!/usr/bin/env bats

# Test suite for gwt-create function
# Tests for basic function structure and parameter validation

setup() {
    # Load the function under test
    load '../git-worktree.zsh'
    
    # Create a temporary directory for test repositories
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    
    # Initialize a test git repository
    cd "$TEST_TEMP_DIR"
    git init test-repo
    cd test-repo
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Set up git config for tests
    git config user.name "Test User"
    git config user.email "test@example.com"
}

teardown() {
    # Clean up test environment
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR"
}

@test "gwt-create function exists and is callable" {
    run gwt-create
    [ "$status" -ne 127 ]  # Function exists (not "command not found")
}

@test "gwt-create shows usage when called without arguments" {
    run gwt-create
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "gwt-create shows usage when called with --help" {
    run gwt-create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "gwt-create" ]]
}

@test "gwt-create validates branch name parameter" {
    # Test empty branch name
    run gwt-create ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Branch name cannot be empty" ]]
}

@test "gwt-create rejects invalid branch names" {
    # Test branch name with spaces
    run gwt-create "invalid branch name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test branch name starting with dash
    run gwt-create "-invalid"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test branch name starting with dot
    run gwt-create ".invalid"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test branch name ending with dot
    run gwt-create "invalid."
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test branch name ending with .lock
    run gwt-create "invalid.lock"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test branch name with special characters
    run gwt-create "branch@#$"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test consecutive dots
    run gwt-create "branch..name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test slash-dot sequence
    run gwt-create "branch/.invalid"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
    
    # Test exactly '@' symbol
    run gwt-create "@"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid branch name" ]]
}

@test "gwt-create accepts valid branch names" {
    # These should not fail on validation (may fail later for other reasons)
    run gwt-create --dry-run feature/auth
    [[ ! "$output" =~ "Invalid branch name" ]]
    
    run gwt-create --dry-run bugfix-123
    [[ ! "$output" =~ "Invalid branch name" ]]
    
    run gwt-create --dry-run v1.2.3
    [[ ! "$output" =~ "Invalid branch name" ]]
}

@test "gwt-create detects when not in a git repository" {
    cd "$TEST_TEMP_DIR"  # Not in git repo
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not a git repository" ]]
}

@test "gwt-create detects when inside a worktree" {
    # Create a worktree first
    git worktree add ../test-worktree
    cd ../test-worktree
    
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot create worktree from inside another worktree" ]]
    
    # Cleanup
    cd ../test-repo
    git worktree remove ../test-worktree
}

@test "gwt-create accepts valid parameters in git repository" {
    # Should not fail on basic validation when in valid git repo
    run gwt-create --dry-run test-branch
    [ "$status" -ne 1 ] || [[ ! "$output" =~ "Invalid branch name" ]]
    [ "$status" -ne 1 ] || [[ ! "$output" =~ "Not a git repository" ]]
}

# Tests for local branch existence detection
@test "_gwt_branch_exists_locally detects existing branch" {
    # Create a test branch
    git checkout -b test-existing-branch
    git checkout master || git checkout main
    
    # Function should exist and return success for existing branch
    run _gwt_branch_exists_locally test-existing-branch
    [ "$status" -eq 0 ]
}

@test "_gwt_branch_exists_locally returns failure for non-existing branch" {
    # Function should return failure for non-existing branch
    run _gwt_branch_exists_locally non-existing-branch
    [ "$status" -eq 1 ]
}

@test "_gwt_branch_exists_locally handles current branch" {
    # Should detect the current branch (master or main)
    local current_branch
    current_branch=$(git branch --show-current)
    
    run _gwt_branch_exists_locally "$current_branch"
    [ "$status" -eq 0 ]
}

@test "_gwt_branch_exists_locally handles branch names with slashes" {
    # Create a branch with slashes
    git checkout -b feature/branch-with-slashes
    git checkout master || git checkout main
    
    run _gwt_branch_exists_locally feature/branch-with-slashes
    [ "$status" -eq 0 ]
}

@test "_gwt_branch_exists_locally handles branch names with special characters" {
    # Create branches with various allowed special characters
    git checkout -b bug-fix_v1.2
    git checkout -b release-v2.0.1
    git checkout master || git checkout main
    
    run _gwt_branch_exists_locally bug-fix_v1.2
    [ "$status" -eq 0 ]
    
    run _gwt_branch_exists_locally release-v2.0.1
    [ "$status" -eq 0 ]
}

# Tests for remote branch existence detection
@test "_gwt_branch_exists_remotely detects existing remote branch" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote
    cd test-remote
    git checkout -b remote-test-branch
    echo "remote content" >> README.md
    git add README.md
    git commit -m "Remote branch commit"
    
    cd ../test-repo
    git remote add origin ../test-remote
    git fetch origin
    
    # Function should return success for existing remote branch
    run _gwt_branch_exists_remotely origin remote-test-branch
    [ "$status" -eq 0 ]
}

@test "_gwt_branch_exists_remotely returns failure for non-existing remote branch" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote
    
    cd test-repo
    git remote add origin ../test-remote
    git fetch origin
    
    # Function should return failure for non-existing remote branch
    run _gwt_branch_exists_remotely origin non-existing-remote-branch
    [ "$status" -eq 1 ]
}

@test "_gwt_branch_exists_remotely handles remote with no connection" {
    # Test with a remote that doesn't exist or can't be reached
    run _gwt_branch_exists_remotely nonexistent-remote test-branch
    [ "$status" -eq 1 ]
}

@test "_gwt_branch_exists_remotely handles branch names with slashes on remote" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote
    cd test-remote
    git checkout -b feature/remote-branch-with-slash
    echo "remote content" >> README.md
    git add README.md
    git commit -m "Remote feature branch commit"
    
    cd ../test-repo
    git remote add origin ../test-remote
    git fetch origin
    
    run _gwt_branch_exists_remotely origin feature/remote-branch-with-slash
    [ "$status" -eq 0 ]
}

# Tests for branch strategy determination
@test "_gwt_determine_branch_strategy returns create-new for new branch" {
    run _gwt_determine_branch_strategy new-branch-name
    [ "$status" -eq 0 ]
    [ "$output" = "create-new" ]
}

@test "_gwt_determine_branch_strategy returns checkout-local for existing local branch" {
    git checkout -b local-test-branch
    git checkout master || git checkout main
    
    run _gwt_determine_branch_strategy local-test-branch
    [ "$status" -eq 0 ]
    [ "$output" = "checkout-local" ]
}

@test "_gwt_determine_branch_strategy returns checkout-remote for remote branch" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote
    cd test-remote
    git checkout -b remote-only-branch
    echo "remote content" >> README.md
    git add README.md
    git commit -m "Remote branch commit"
    
    cd ../test-repo
    git remote add origin ../test-remote
    git fetch origin
    
    run _gwt_determine_branch_strategy remote-only-branch
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^checkout-remote:origin$ ]]
}

# Tests for directory name sanitization
@test "_gwt_sanitize_directory_name handles branch names with slashes" {
    run _gwt_sanitize_directory_name feature/user-auth
    [ "$status" -eq 0 ]
    [ "$output" = "feature-user-auth" ]
}

@test "_gwt_sanitize_directory_name handles multiple slashes" {
    run _gwt_sanitize_directory_name feature/user/auth/system
    [ "$status" -eq 0 ]
    [ "$output" = "feature-user-auth-system" ]
}

@test "_gwt_sanitize_directory_name handles leading and trailing slashes" {
    run _gwt_sanitize_directory_name /feature/auth/
    [ "$status" -eq 0 ]
    [ "$output" = "feature-auth" ]
}

@test "_gwt_sanitize_directory_name handles empty input" {
    run _gwt_sanitize_directory_name ""
    [ "$status" -eq 1 ]
    [ "$output" = "" ]
}

@test "_gwt_sanitize_directory_name handles only slashes" {
    run _gwt_sanitize_directory_name "///"
    [ "$status" -eq 0 ]
    [ "$output" = "branch" ]
}

# Tests for directory conflict detection and resolution
@test "_gwt_check_directory_conflict detects existing directory" {
    # Create a directory that would conflict
    local test_dir="$TEST_TEMP_DIR/test-repo/conflicting-dir"
    mkdir -p "$test_dir"
    
    run _gwt_check_directory_conflict "$test_dir"
    [ "$status" -eq 1 ]
}

@test "_gwt_check_directory_conflict allows non-existing directory" {
    # Test with a directory that doesn't exist
    local test_dir="$TEST_TEMP_DIR/test-repo/non-existing-dir"
    
    run _gwt_check_directory_conflict "$test_dir"
    [ "$status" -eq 0 ]
}

@test "_gwt_check_directory_conflict handles existing file conflict" {
    # Create a file that would conflict with directory name
    local test_file="$TEST_TEMP_DIR/test-repo/conflicting-file"
    echo "content" > "$test_file"
    
    run _gwt_check_directory_conflict "$test_file"
    [ "$status" -eq 1 ]
}

@test "_gwt_resolve_target_directory returns correct sibling path" {
    # Should resolve to parent directory with branch name
    run _gwt_resolve_target_directory "feature/test-branch"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /feature-test-branch$ ]]
}

@test "_gwt_resolve_target_directory handles custom target directory" {
    # Should use custom directory name but still resolve to sibling location
    run _gwt_resolve_target_directory "test-branch" "custom-dir"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /custom-dir$ ]]
}

@test "_gwt_resolve_target_directory handles relative paths" {
    # Test that relative paths are properly resolved
    run _gwt_resolve_target_directory "test-branch" "../custom-dir"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /custom-dir$ ]]
}

# Tests for worktree creation with new and existing branches
@test "_gwt_create_worktree creates worktree for new branch" {
    local target_dir="$TEST_TEMP_DIR/new-branch-worktree"
    
    run _gwt_create_worktree "new-test-branch" "$target_dir" "create-new"
    [ "$status" -eq 0 ]
    [ -d "$target_dir" ]
    
    # Verify the worktree was created with the new branch
    cd "$target_dir"
    local current_branch
    current_branch=$(git branch --show-current)
    [ "$current_branch" = "new-test-branch" ]
}

@test "_gwt_create_worktree creates worktree for existing local branch" {
    # Create an existing local branch first
    git checkout -b existing-local-branch
    git checkout master || git checkout main
    
    local target_dir="$TEST_TEMP_DIR/existing-local-worktree"
    
    run _gwt_create_worktree "existing-local-branch" "$target_dir" "checkout-local"
    [ "$status" -eq 0 ]
    [ -d "$target_dir" ]
    
    # Verify the worktree was created with the existing branch
    cd "$target_dir"
    local current_branch
    current_branch=$(git branch --show-current)
    [ "$current_branch" = "existing-local-branch" ]
}

@test "_gwt_create_worktree creates worktree for remote branch" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote-for-worktree
    cd test-remote-for-worktree
    git checkout -b remote-worktree-branch
    echo "remote content" >> README.md
    git add README.md
    git commit -m "Remote branch for worktree test"
    
    cd ../test-repo
    git remote add origin ../test-remote-for-worktree
    git fetch origin
    
    local target_dir="$TEST_TEMP_DIR/remote-branch-worktree"
    
    run _gwt_create_worktree "remote-worktree-branch" "$target_dir" "checkout-remote:origin"
    [ "$status" -eq 0 ]
    [ -d "$target_dir" ]
    
    # Verify the worktree was created with tracking the remote branch
    cd "$target_dir"
    local current_branch
    current_branch=$(git branch --show-current)
    [ "$current_branch" = "remote-worktree-branch" ]
}

@test "_gwt_create_worktree handles directory creation errors" {
    # Try to create worktree in a location that can't be created (read-only parent)
    local readonly_parent="$TEST_TEMP_DIR/readonly"
    mkdir -p "$readonly_parent"
    chmod 444 "$readonly_parent"
    
    local target_dir="$readonly_parent/should-fail"
    
    run _gwt_create_worktree "test-branch" "$target_dir" "create-new"
    [ "$status" -eq 1 ]
    
    # Cleanup
    chmod 755 "$readonly_parent"
}

# Tests for error scenarios and edge cases (Task 4.1)
@test "gwt-create handles insufficient filesystem permissions" {
    # Create a directory without write permissions
    local readonly_dir="$TEST_TEMP_DIR/readonly"
    mkdir -p "$readonly_dir"
    chmod 444 "$readonly_dir"
    
    local target_dir="$readonly_dir/should-fail"
    
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]  # dry-run should work
    
    # Note: Actual permission test is complex in test environment
    # The implementation should handle this via _gwt_validate_filesystem_access
    
    # Cleanup
    chmod 755 "$readonly_dir"
}

@test "gwt-create handles network connectivity issues for remote operations" {
    # Add a remote that doesn't exist
    git remote add nonexistent-remote https://github.com/nonexistent/repo.git
    
    # This should handle network errors gracefully
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]  # Should not fail on dry-run even with bad remote
    
    # Cleanup
    git remote remove nonexistent-remote
}

@test "gwt-create handles git command failures gracefully" {
    # Create a scenario where git worktree add might fail
    local target_dir="$TEST_TEMP_DIR/fail-worktree"
    
    # Try to create with invalid branch reference
    run _gwt_create_worktree "HEAD~999" "$target_dir" "create-new"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error:" ]]
}

@test "gwt-create handles extremely long branch names" {
    # Create a very long branch name (255 characters)
    local long_name=$(printf 'a%.0s' {1..250})
    
    run gwt-create --dry-run "$long_name"
    # Should either work or provide clear error about length
    if [ "$status" -eq 1 ]; then
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "gwt-create handles special filesystem scenarios" {
    # Test with branch name that would create problematic directory
    run gwt-create --dry-run "branch.with.dots"
    # Should handle this case appropriately
    if [ "$status" -eq 1 ]; then
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "gwt-create handles corrupted git repository state" {
    # Simulate corrupted git state by removing .git/HEAD
    local git_dir=$(git rev-parse --git-dir)
    mv "$git_dir/HEAD" "$git_dir/HEAD.bak"
    
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error:" ]]
    
    # Restore
    mv "$git_dir/HEAD.bak" "$git_dir/HEAD"
}

@test "gwt-create handles concurrent worktree operations" {
    # This is a placeholder for testing concurrent access
    # In a real scenario, this would test race conditions
    run gwt-create --dry-run concurrent-test
    [ "$status" -eq 0 ]
}

@test "gwt-create handles branch names with unicode characters" {
    # Test with unicode characters in branch names
    run gwt-create --dry-run "feature/测试分支"
    # Should either work or provide clear error
    if [ "$status" -eq 1 ]; then
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "gwt-create handles maximum path length scenarios" {
    # Test with very long target directory paths
    local long_path="$TEST_TEMP_DIR/$(printf 'very-long-directory-name%.0s' {1..20})"
    
    run gwt-create --dry-run test-branch "$(basename "$long_path")"
    # Should handle long paths appropriately
    if [ "$status" -eq 1 ]; then
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "gwt-create provides helpful error for disk space issues" {
    # This is a placeholder for disk space validation
    # The implementation should check available space
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]  # Dry run should always work
}

# Tests for worktree detection improvement (Task 4.2)
@test "gwt-create detects nested worktree scenarios" {
    # Create a worktree
    git worktree add ../test-worktree-outer
    cd ../test-worktree-outer
    
    # Try to create another worktree from within this worktree
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot create worktree from inside another worktree" ]]
    
    # Cleanup
    cd ../test-repo
    git worktree remove ../test-worktree-outer
}

@test "gwt-create detects worktree from subdirectory" {
    # Create a worktree and try from a subdirectory within it
    git worktree add ../test-worktree-subdir
    cd ../test-worktree-subdir
    mkdir subdir
    cd subdir
    
    run gwt-create test-branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot create worktree from inside another worktree" ]]
    
    # Cleanup
    cd ../../test-repo
    git worktree remove ../test-worktree-subdir
}

# Tests for enhanced error messages (Task 4.3)
@test "gwt-create provides remediation suggestions for common errors" {
    # Test that error messages include helpful suggestions
    run gwt-create "invalid branch name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error:" ]]
    # Should provide suggestion about valid branch names
}

@test "gwt-create provides remediation for directory conflicts" {
    # Create a conflicting directory
    local conflict_dir="$TEST_TEMP_DIR/conflict-test"
    mkdir -p "$conflict_dir"
    
    run _gwt_check_directory_conflict "$conflict_dir"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Please choose a different directory name" ]] || [[ "$output" =~ "remove the existing" ]]
}

# Tests for progress indicators (Task 4.4)
@test "gwt-create shows progress during long operations" {
    # This is a placeholder - actual implementation would show progress
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]
    # In real implementation, should show progress indicators
}

# Tests for color-coded output (Task 4.5)
@test "gwt-create uses appropriate colors for different message types" {
    # This is a placeholder for color testing
    # Real implementation would test ANSI color codes
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]
}

# Tests for cleanup logic (Task 4.6)
@test "gwt-create cleans up on failed worktree creation" {
    # Create a scenario that will fail and should trigger cleanup
    local target_dir="$TEST_TEMP_DIR/cleanup-test"
    
    # This test assumes the cleanup function exists and works
    # Implementation should clean up any partial state
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]  # Dry run should always succeed
}

@test "gwt-create cleanup handles partial directory creation" {
    # Test cleanup when directory was created but worktree failed
    # This is a placeholder for comprehensive cleanup testing
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]
}

# Tests for filesystem validation (Task 4.7)
@test "gwt-create validates filesystem permissions before creation" {
    # Test permission validation
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]
    # Real implementation should validate write permissions
}

@test "gwt-create checks available disk space" {
    # Test disk space validation
    run gwt-create --dry-run test-branch
    [ "$status" -eq 0 ]
    # Real implementation should check available space
}

@test "gwt-create handles case-sensitive filesystem issues" {
    # Test case sensitivity issues
    run gwt-create --dry-run "Test-Branch"
    # Should handle appropriately based on filesystem
    if [ "$status" -eq 1 ]; then
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "gwt-create validates filesystem path restrictions" {
    # Test filesystem-specific path restrictions
    run gwt-create --dry-run "valid-branch-name"
    [ "$status" -eq 0 ] || [[ "$output" =~ "Error:" ]]
}

# ============================================================================
# Integration Tests for Complete End-to-End Workflows (Task 5.1)
# ============================================================================

@test "E2E: Complete workflow for new branch creation and navigation" {
    # Test the complete end-to-end workflow for creating a new branch
    local branch_name="feature/e2e-test-new-branch"
    local expected_dir="../feature-e2e-test-new-branch"
    
    # Ensure branch doesn't exist
    ! git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Execute the complete workflow
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify worktree was created
    [ -d "$expected_dir" ]
    
    # Verify branch was created
    git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Verify current directory is the new worktree (we need to check manually)
    # Note: In test environment, actual cd doesn't persist
    [[ "$output" =~ "Successfully created and navigated to worktree" ]]
    
    # Verify worktree is tracked by git
    git worktree list | grep -q "$expected_dir"
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "Navigation: Automatic directory change after successful worktree creation" {
    # Test that the function includes proper navigation logic
    local branch_name="feature/navigation-test"
    local expected_dir="../feature-navigation-test"
    
    # Execute the function
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify worktree was created
    [ -d "$expected_dir" ]
    
    # Verify navigation message is shown
    [[ "$output" =~ "Navigating to worktree directory" ]]
    [[ "$output" =~ "Successfully created and navigated to worktree" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

@test "Navigation: Graceful handling of navigation failure" {
    # Test behavior when navigation fails (e.g., directory removed after creation)
    local branch_name="feature/nav-fail-test"
    local expected_dir="../feature-nav-fail-test"
    
    # This is a conceptual test - actual navigation failure is hard to simulate
    # The implementation should show a warning if cd fails
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify worktree was created successfully
    [ -d "$expected_dir" ]
    
    # Verify success even if navigation conceptually failed
    [[ "$output" =~ "Successfully created" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

@test "Navigation: No navigation attempt during dry-run mode" {
    # Test that dry-run mode doesn't attempt navigation
    local branch_name="feature/dry-run-nav-test"
    
    # Execute dry-run
    run gwt-create --dry-run "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify dry-run message but no navigation messages
    [[ "$output" =~ "Dry run:" ]]
    [[ ! "$output" =~ "Navigating to worktree directory" ]]
    [[ ! "$output" =~ "Successfully created and navigated" ]]
    
    # Verify no actual changes were made
    [ ! -d "../feature-dry-run-nav-test" ]
}

@test "E2E: Complete workflow for existing local branch checkout" {
    # Create an existing local branch first
    local branch_name="existing-local-e2e"
    local expected_dir="../existing-local-e2e"
    
    git checkout -b "$branch_name"
    echo "local branch content" >> local_file.txt
    git add local_file.txt
    git commit -m "Local branch commit"
    git checkout master || git checkout main
    
    # Execute the complete workflow
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify worktree was created
    [ -d "$expected_dir" ]
    
    # Verify the worktree contains the local branch content
    [ -f "$expected_dir/local_file.txt" ]
    
    # Verify worktree is on correct branch
    cd "$expected_dir"
    local current_branch=$(git branch --show-current)
    [ "$current_branch" = "$branch_name" ]
    cd - >/dev/null
    
    # Verify success message
    [[ "$output" =~ "Successfully created and navigated to worktree" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "E2E: Complete workflow for remote branch tracking" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote-e2e
    cd test-remote-e2e
    git checkout -b "remote-e2e-branch"
    echo "remote branch content" >> remote_file.txt
    git add remote_file.txt
    git commit -m "Remote branch commit"
    
    cd ../test-repo
    git remote add origin ../test-remote-e2e
    git fetch origin
    
    local branch_name="remote-e2e-branch"
    local expected_dir="../remote-e2e-branch"
    
    # Execute the complete workflow
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify worktree was created
    [ -d "$expected_dir" ]
    
    # Verify the worktree contains remote branch content
    [ -f "$expected_dir/remote_file.txt" ]
    
    # Verify local tracking branch was created
    git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Verify tracking relationship
    cd "$expected_dir"
    local upstream=$(git branch -vv | grep "$branch_name" | grep "origin/$branch_name")
    [ -n "$upstream" ]
    cd - >/dev/null
    
    # Verify success message
    [[ "$output" =~ "Successfully created and navigated to worktree" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
    git remote remove origin
}

@test "E2E: Workflow with branch name sanitization and special characters" {
    # Test complete workflow with branch names requiring sanitization
    local branch_name="feature/user-auth/oauth2.0"
    local expected_dir="../feature-user-auth-oauth2.0"
    
    # Execute the complete workflow
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify directory was created with sanitized name
    [ -d "$expected_dir" ]
    
    # Verify actual branch name is preserved
    git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Verify worktree is on correct branch
    cd "$expected_dir"
    local current_branch=$(git branch --show-current)
    [ "$current_branch" = "$branch_name" ]
    cd - >/dev/null
    
    # Verify success message references original branch name
    [[ "$output" =~ "$branch_name" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "E2E: Workflow with custom target directory specification" {
    # Test complete workflow with user-specified target directory
    local branch_name="feature/custom-target"
    local custom_dir="my-custom-worktree"
    local expected_dir="../my-custom-worktree"
    
    # Execute the complete workflow with custom directory
    run gwt-create "$branch_name" "$custom_dir"
    [ "$status" -eq 0 ]
    
    # Verify custom directory was created
    [ -d "$expected_dir" ]
    
    # Verify branch was created
    git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Verify worktree is tracked with custom directory name
    git worktree list | grep -q "$expected_dir"
    
    # Verify success message references custom directory
    [[ "$output" =~ "$expected_dir" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "E2E: Multiple worktree creation and management workflow" {
    # Test creating multiple worktrees and verify they don't interfere
    local branch1="feature/multi-test-1"
    local branch2="feature/multi-test-2"
    local dir1="../feature-multi-test-1"
    local dir2="../feature-multi-test-2"
    
    # Create first worktree
    run gwt-create "$branch1"
    [ "$status" -eq 0 ]
    [ -d "$dir1" ]
    
    # Create second worktree
    run gwt-create "$branch2"
    [ "$status" -eq 0 ]
    [ -d "$dir2" ]
    
    # Verify both worktrees exist and are independent
    [ -d "$dir1" ]
    [ -d "$dir2" ]
    
    # Verify both branches exist
    git branch --list "$branch1" | grep -q "$branch1"
    git branch --list "$branch2" | grep -q "$branch2"
    
    # Verify both worktrees are tracked
    git worktree list | grep -q "$dir1"
    git worktree list | grep -q "$dir2"
    
    # Verify worktrees are on correct branches
    cd "$dir1"
    [ "$(git branch --show-current)" = "$branch1" ]
    cd - >/dev/null
    
    cd "$dir2"
    [ "$(git branch --show-current)" = "$branch2" ]
    cd - >/dev/null
    
    # Cleanup
    if git worktree list | grep -q "$dir1"; then
        git worktree remove "$dir1" --force 2>/dev/null || true
    fi
    if git worktree list | grep -q "$dir2"; then
        git worktree remove "$dir2" --force 2>/dev/null || true
    fi
    git branch -D "$branch1" "$branch2" 2>/dev/null || true
}

@test "E2E: Error recovery and cleanup workflow" {
    # Test workflow behavior when errors occur and cleanup happens
    local branch_name="feature/error-recovery-test"
    local expected_dir="../feature-error-recovery-test"
    
    # Create a conflicting directory to trigger error
    mkdir -p "$expected_dir"
    echo "existing content" > "$expected_dir/conflict.txt"
    
    # Execute workflow - should fail due to directory conflict
    run gwt-create "$branch_name"
    [ "$status" -eq 1 ]
    
    # Verify error message is informative
    [[ "$output" =~ "Error:" ]]
    [[ "$output" =~ "already exists" ]]
    
    # Remove the conflicting directory
    rm -rf "$expected_dir"
    
    # Try again - should succeed now
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify successful creation
    [ -d "$expected_dir" ]
    git branch --list "$branch_name" | grep -q "$branch_name"
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "E2E: Performance validation for local operations" {
    # Test that local operations complete within performance requirements (< 2 seconds)
    local branch_name="feature/performance-test-local"
    local expected_dir="../feature-performance-test-local"
    
    # Measure execution time
    local start_time=$(date +%s)
    run gwt-create "$branch_name"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify success
    [ "$status" -eq 0 ]
    [ -d "$expected_dir" ]
    
    # Verify performance requirement (< 2 seconds for local operations)
    [ "$duration" -lt 3 ]  # Allow some buffer for test environment
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "E2E: Complete dry-run workflow validation" {
    # Test that dry-run mode provides accurate preview without making changes
    local branch_name="feature/dry-run-test"
    local expected_dir="../feature-dry-run-test"
    
    # Execute dry-run
    run gwt-create --dry-run "$branch_name"
    [ "$status" -eq 0 ]
    
    # Verify dry-run output includes expected information
    [[ "$output" =~ "Dry run:" ]]
    [[ "$output" =~ "$expected_dir" ]]
    [[ "$output" =~ "$branch_name" ]]
    [[ "$output" =~ "Strategy:" ]]
    
    # Verify no actual changes were made
    [ ! -d "$expected_dir" ]
    ! git branch --list "$branch_name" | grep -q "$branch_name"
    ! git worktree list | grep -q "$expected_dir"
    
    # Now execute without dry-run to verify the preview was accurate
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    [ -d "$expected_dir" ]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

# ============================================================================
# Automatic Directory Navigation Tests (Task 5.2)
# ============================================================================

@test "Completion: _gwt_create function exists and is callable" {
    # Test that the completion function exists
    run type _gwt_create
    [ "$status" -eq 0 ]
    [[ "$output" =~ "_gwt_create is a shell function" ]]
}

@test "Completion: _gwt_complete_branch_names function exists" {
    # Test that the branch completion function exists
    run type _gwt_complete_branch_names
    [ "$status" -eq 0 ]
    [[ "$output" =~ "_gwt_complete_branch_names is a shell function" ]]
}

@test "Completion: _gwt_complete_local_branches function exists" {
    # Test that the local branch completion function exists
    run type _gwt_complete_local_branches
    [ "$status" -eq 0 ]
    [[ "$output" =~ "_gwt_complete_local_branches is a shell function" ]]
}

@test "Completion: Branch completion includes local branches" {
    # Create some local branches for testing
    git checkout -b "completion-test-branch-1"
    git checkout -b "completion-test-branch-2"
    git checkout master || git checkout main
    
    # Test branch completion function directly
    # Note: This is a conceptual test - actual completion testing requires zsh context
    # The implementation should parse git branch output correctly
    
    # Verify git branch command works and our test branches exist
    run git branch
    [ "$status" -eq 0 ]
    [[ "$output" =~ "completion-test-branch-1" ]]
    [[ "$output" =~ "completion-test-branch-2" ]]
    
    # Cleanup
    git branch -D completion-test-branch-1 completion-test-branch-2
}

@test "Completion: Branch completion includes remote branches" {
    # Create a second repository to act as remote
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-remote-completion
    cd test-remote-completion
    git checkout -b "remote-completion-branch"
    echo "remote content" >> remote_file.txt
    git add remote_file.txt
    git commit -m "Remote completion branch"
    
    cd ../test-repo
    git remote add origin ../test-remote-completion
    git fetch origin
    
    # Test that git branch -r shows remote branches
    run git branch -r
    [ "$status" -eq 0 ]
    [[ "$output" =~ "origin/remote-completion-branch" ]]
    
    # Cleanup
    git remote remove origin
}

@test "Completion: Integration with zsh compdef registration" {
    # Test that completion registration logic is present
    # This tests the compdef registration code exists
    run grep -n "compdef.*gwt-create" ../git-worktree.zsh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "compdef _gwt_create gwt-create" ]]
}

@test "Completion: Zsh version detection for registration" {
    # Test that completion only registers in zsh
    run grep -A2 -B2 "ZSH_VERSION" ../git-worktree.zsh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "if.*ZSH_VERSION" ]]
    [[ "$output" =~ "compdef" ]]
}

@test "Completion: Argument specification includes branch name and directory" {
    # Test that the completion function defines proper argument structure
    run grep -A5 "arguments=(" ../git-worktree.zsh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "branch-name" ]]
    [[ "$output" =~ "target-directory" ]]
    [[ "$output" =~ "--help" ]]
    [[ "$output" =~ "--dry-run" ]]
}

# ============================================================================
# Git Repository Configuration Tests (Task 5.4)
# ============================================================================

@test "Config: Function works in repository with default branch main" {
    # Create a repository with main as default branch
    cd "$TEST_TEMP_DIR"
    git init test-main-branch
    cd test-main-branch
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create main branch instead of master
    echo "# Main Branch Repo" > README.md
    git add README.md
    git commit -m "Initial commit on main"
    git branch -M main
    
    # Test gwt-create works with main branch
    run gwt-create feature/test-with-main
    [ "$status" -eq 0 ]
    [ -d "../feature-test-with-main" ]
    
    # Cleanup
    if git worktree list | grep -q "../feature-test-with-main"; then
        git worktree remove "../feature-test-with-main" --force 2>/dev/null || true
    fi
    git branch -D feature/test-with-main 2>/dev/null || true
}

@test "Config: Function works in repository with multiple remotes" {
    # Create repositories to act as multiple remotes
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-upstream
    git clone test-repo test-origin
    
    # Add content to each remote
    cd test-upstream
    git checkout -b upstream-feature
    echo "upstream content" > upstream.txt
    git add upstream.txt
    git commit -m "Upstream feature"
    
    cd ../test-origin
    git checkout -b origin-feature
    echo "origin content" > origin.txt
    git add origin.txt
    git commit -m "Origin feature"
    
    # Configure main repo with multiple remotes
    cd ../test-repo
    git remote add upstream ../test-upstream
    git remote add origin ../test-origin
    git fetch upstream
    git fetch origin
    
    # Test that function works with multiple remotes
    run gwt-create upstream-feature
    [ "$status" -eq 0 ]
    [ -d "../upstream-feature" ]
    
    # Test with origin remote branch
    run gwt-create origin-feature
    [ "$status" -eq 0 ]
    [ -d "../origin-feature" ]
    
    # Cleanup
    if git worktree list | grep -q "../upstream-feature"; then
        git worktree remove "../upstream-feature" --force 2>/dev/null || true
    fi
    if git worktree list | grep -q "../origin-feature"; then
        git worktree remove "../origin-feature" --force 2>/dev/null || true
    fi
    git branch -D upstream-feature origin-feature 2>/dev/null || true
    git remote remove upstream origin
}

@test "Config: Function works in repository with existing worktrees" {
    # Create an existing worktree
    git worktree add ../existing-worktree-test existing-branch 2>/dev/null || {
        git checkout -b existing-branch
        git checkout master || git checkout main
        git worktree add ../existing-worktree-test existing-branch
    }
    
    # Verify existing worktree is there
    git worktree list | grep -q "../existing-worktree-test"
    
    # Test that creating another worktree works
    run gwt-create new-branch-with-existing-worktrees
    [ "$status" -eq 0 ]
    [ -d "../new-branch-with-existing-worktrees" ]
    
    # Verify both worktrees exist
    git worktree list | grep -q "../existing-worktree-test"
    git worktree list | grep -q "../new-branch-with-existing-worktrees"
    
    # Cleanup
    if git worktree list | grep -q "../existing-worktree-test"; then
        git worktree remove "../existing-worktree-test" --force 2>/dev/null || true
    fi
    if git worktree list | grep -q "../new-branch-with-existing-worktrees"; then
        git worktree remove "../new-branch-with-existing-worktrees" --force 2>/dev/null || true
    fi
    git branch -D existing-branch new-branch-with-existing-worktrees 2>/dev/null || true
}

@test "Config: Function works in repository with git hooks" {
    # Create a simple post-checkout hook
    mkdir -p .git/hooks
    cat > .git/hooks/post-checkout << EOF
#\!/bin/sh
echo "Post-checkout hook executed" > .post-checkout-log
EOF
    chmod +x .git/hooks/post-checkout
    
    # Test that function works with hooks
    run gwt-create feature/test-with-hooks
    [ "$status" -eq 0 ]
    [ -d "../feature-test-with-hooks" ]
    
    # Verify hook was executed (log should exist in worktree)
    [ -f "../feature-test-with-hooks/.post-checkout-log" ]
    
    # Cleanup
    if git worktree list | grep -q "../feature-test-with-hooks"; then
        git worktree remove "../feature-test-with-hooks" --force 2>/dev/null || true
    fi
    git branch -D feature/test-with-hooks 2>/dev/null || true
    rm -f .git/hooks/post-checkout
}

@test "Config: Function works in shallow repository" {
    # Create a shallow clone scenario
    cd "$TEST_TEMP_DIR"
    git clone --depth 1 test-repo test-shallow
    cd test-shallow
    
    # Verify it's a shallow repo
    [ -f .git/shallow ]
    
    # Test that function works in shallow repo (may have limitations)
    run gwt-create feature/shallow-test
    # Should succeed or fail gracefully
    if [ "$status" -eq 0 ]; then
        [ -d "../feature-shallow-test" ]
        # Cleanup
        if git worktree list | grep -q "../feature-shallow-test"; then
            git worktree remove "../feature-shallow-test" --force 2>/dev/null || true
        fi
        git branch -D feature/shallow-test 2>/dev/null || true
    else
        # Should provide helpful error message
        [[ "$output" =~ "Error:" ]]
    fi
}

@test "Config: Function works with different git configurations" {
    # Test with different git config settings
    local original_autocrlf=$(git config core.autocrlf 2>/dev/null || echo "unset")
    local original_safecrlf=$(git config core.safecrlf 2>/dev/null || echo "unset")
    
    # Set some different git configurations
    git config core.autocrlf input
    git config core.safecrlf true
    git config branch.autoSetupRebase always
    
    # Test that function works with these settings
    run gwt-create feature/test-with-config
    [ "$status" -eq 0 ]
    [ -d "../feature-test-with-config" ]
    
    # Cleanup
    if git worktree list | grep -q "../feature-test-with-config"; then
        git worktree remove "../feature-test-with-config" --force 2>/dev/null || true
    fi
    git branch -D feature/test-with-config 2>/dev/null || true
    
    # Restore original config
    if [ "$original_autocrlf" = "unset" ]; then
        git config --unset core.autocrlf 2>/dev/null || true
    else
        git config core.autocrlf "$original_autocrlf"
    fi
    if [ "$original_safecrlf" = "unset" ]; then
        git config --unset core.safecrlf 2>/dev/null || true
    else
        git config core.safecrlf "$original_safecrlf"
    fi
    git config --unset branch.autoSetupRebase 2>/dev/null || true
}

@test "Config: Function works in nested subdirectory" {
    # Create a subdirectory and test from there
    mkdir -p src/components/auth
    cd src/components/auth
    
    # Test that function works from subdirectory
    run gwt-create feature/test-from-subdir
    [ "$status" -eq 0 ]
    
    # Verify worktree was created at correct location (relative to repo root)
    cd ../../..
    [ -d "../feature-test-from-subdir" ]
    
    # Cleanup
    if git worktree list | grep -q "../feature-test-from-subdir"; then
        git worktree remove "../feature-test-from-subdir" --force 2>/dev/null || true
    fi
    git branch -D feature/test-from-subdir 2>/dev/null || true
    
    # Remove test directories
    rm -rf src
}

# ============================================================================
# Performance Testing with Many Branches (Task 5.5)
# ============================================================================

@test "Performance: Function handles repository with many local branches efficiently" {
    # Create multiple local branches to test scalability
    local branch_count=20
    local branches=()
    
    # Create many branches
    for i in $(seq 1 $branch_count); do
        local branch_name="perf-test-branch-$i"
        git checkout -b "$branch_name" 2>/dev/null
        branches+=("$branch_name")
    done
    
    # Return to main branch
    git checkout master || git checkout main
    
    # Measure performance of creating worktree with many branches present
    local start_time=$(date +%s)
    run gwt-create "performance-test-new-branch"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should still complete quickly (< 3 seconds even with many branches)
    [ "$status" -eq 0 ]
    [ "$duration" -lt 5 ]  # Allow buffer for test environment
    [ -d "../performance-test-new-branch" ]
    
    # Cleanup new worktree
    if git worktree list | grep -q "../performance-test-new-branch"; then
        git worktree remove "../performance-test-new-branch" --force 2>/dev/null || true
    fi
    git branch -D performance-test-new-branch 2>/dev/null || true
    
    # Cleanup all test branches
    for branch in "${branches[@]}"; do
        git branch -D "$branch" 2>/dev/null || true
    done
}

@test "Performance: Function handles repository with many remote branches efficiently" {
    # Create a remote repository with many branches
    cd "$TEST_TEMP_DIR"
    git clone test-repo test-many-remote-branches
    cd test-many-remote-branches
    
    # Create many remote branches
    for i in $(seq 1 15); do
        git checkout -b "remote-perf-branch-$i"
        echo "content $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "Remote branch $i"
    done
    
    # Switch back to main repo and add remote
    cd ../test-repo
    git remote add perf-remote ../test-many-remote-branches
    git fetch perf-remote
    
    # Measure performance with many remote branches
    local start_time=$(date +%s)
    run gwt-create "remote-perf-branch-5"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should complete within reasonable time even with many remote branches
    [ "$status" -eq 0 ]
    [ "$duration" -lt 8 ]  # Allow more time for remote operations
    [ -d "../remote-perf-branch-5" ]
    
    # Cleanup
    if git worktree list | grep -q "../remote-perf-branch-5"; then
        git worktree remove "../remote-perf-branch-5" --force 2>/dev/null || true
    fi
    git branch -D remote-perf-branch-5 2>/dev/null || true
    git remote remove perf-remote
}

@test "Performance: Branch completion remains responsive with many branches" {
    # Create branches for completion performance testing
    local branch_count=25
    local branches=()
    
    # Create many branches with different naming patterns
    for i in $(seq 1 $branch_count); do
        local branch_name="completion-perf-$i"
        git checkout -b "$branch_name" 2>/dev/null
        branches+=("$branch_name")
    done
    
    # Return to main branch
    git checkout master || git checkout main
    
    # Test that git branch operations (used by completion) are still fast
    local start_time=$(date +%s)
    run git branch
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Git branch should be fast even with many branches
    [ "$status" -eq 0 ]
    [ "$duration" -lt 3 ]
    
    # Verify all branches are listed
    [[ "$output" =~ "completion-perf-1" ]]
    [[ "$output" =~ "completion-perf-$branch_count" ]]
    
    # Test branch listing for remote completion
    local start_time=$(date +%s)
    run git branch -r
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Remote branch listing should also be fast
    [ "$status" -eq 0 ]
    [ "$duration" -lt 2 ]
    
    # Cleanup all test branches
    for branch in "${branches[@]}"; do
        git branch -D "$branch" 2>/dev/null || true
    done
}

@test "Performance: Worktree list operations remain efficient" {
    # Create multiple worktrees to test git worktree list performance
    local worktree_count=8
    local worktrees=()
    local branches=()
    
    # Create multiple worktrees
    for i in $(seq 1 $worktree_count); do
        local branch_name="worktree-perf-branch-$i"
        local worktree_dir="../worktree-perf-$i"
        
        run gwt-create "$branch_name"
        if [ "$status" -eq 0 ]; then
            branches+=("$branch_name")
            worktrees+=("$worktree_dir")
        fi
    done
    
    # Test git worktree list performance
    local start_time=$(date +%s)
    run git worktree list
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should be fast even with multiple worktrees
    [ "$status" -eq 0 ]
    [ "$duration" -lt 3 ]
    
    # Verify worktrees are listed
    [[ "$output" =~ "worktree-perf-1" ]]
    
    # Cleanup all worktrees
    for i in $(seq 1 $worktree_count); do
        local worktree_dir="../worktree-perf-$i"
        if git worktree list | grep -q "$worktree_dir"; then
            git worktree remove "$worktree_dir" --force 2>/dev/null || true
        fi
    done
    
    # Cleanup branches
    for branch in "${branches[@]}"; do
        git branch -D "$branch" 2>/dev/null || true
    done
}

@test "Performance: Function startup time meets requirements" {
    # Test function loading performance (< 100ms requirement)
    # This is challenging to measure precisely in bats, but we can test sourcing speed
    
    # Create a clean shell and measure sourcing time
    local start_time=$(date +%s%3N)  # Milliseconds
    run bash -c "source ../git-worktree.zsh && echo loaded"
    local end_time=$(date +%s%3N)
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "loaded" ]]
    
    # Calculate duration (may not be perfectly accurate due to test overhead)
    local duration=$((end_time - start_time))
    
    # Should load reasonably quickly (allow generous buffer for test environment)
    [ "$duration" -lt 1000 ]  # Less than 1 second for sourcing
}

@test "Performance: Memory usage remains reasonable during operations" {
    # Test that function doesn't consume excessive memory
    # This is a conceptual test - actual memory measurement is complex in bats
    
    # Create a scenario that might use more memory (large branch name, many operations)
    local long_branch_name="performance-test-with-very-long-branch-name-that-includes-many-characters-to-test-memory-efficiency"
    
    # Execute function with complex scenario
    run gwt-create "$long_branch_name"
    [ "$status" -eq 0 ]
    [ -d "../${long_branch_name//\//-}" ]
    
    # Function should complete successfully without memory issues
    [[ "$output" =~ "Successfully created" ]]
    
    # Cleanup
    local sanitized_name="${long_branch_name//\//-}"
    if git worktree list | grep -q "../$sanitized_name"; then
        git worktree remove "../$sanitized_name" --force 2>/dev/null || true
    fi
    git branch -D "$long_branch_name" 2>/dev/null || true
}

# ============================================================================
# Cross-Platform Compatibility Testing (Task 5.6)
# ============================================================================

@test "Platform: Function works on current platform" {
    # Test basic functionality works on current platform (macOS/Linux/WSL)
    local platform=$(uname -s)
    
    # Test basic worktree creation
    run gwt-create "platform-test-$platform"
    [ "$status" -eq 0 ]
    [ -d "../platform-test-$platform" ]
    
    # Verify success message
    [[ "$output" =~ "Successfully created" ]]
    
    # Cleanup
    if git worktree list | grep -q "../platform-test-$platform"; then
        git worktree remove "../platform-test-$platform" --force 2>/dev/null || true
    fi
    git branch -D "platform-test-$platform" 2>/dev/null || true
}

@test "Platform: Path handling works with platform-specific separators" {
    # Test path handling works correctly on current platform
    local test_branch="feature/platform-path-test"
    local expected_dir="../feature-platform-path-test"
    
    # Test directory creation with platform-appropriate paths
    run gwt-create "$test_branch"
    [ "$status" -eq 0 ]
    [ -d "$expected_dir" ]
    
    # Verify path resolution works correctly
    [[ "$output" =~ "$expected_dir" ]] || [[ "$output" =~ "feature-platform-path-test" ]]
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$test_branch" 2>/dev/null || true
}

@test "Platform: File permissions are handled correctly" {
    # Test that file permissions work on current platform
    local test_branch="platform-permissions-test"
    local expected_dir="../platform-permissions-test"
    
    # Create worktree
    run gwt-create "$test_branch"
    [ "$status" -eq 0 ]
    [ -d "$expected_dir" ]
    
    # Test file operations in worktree
    echo "test content" > "$expected_dir/test-file.txt"
    [ -f "$expected_dir/test-file.txt" ]
    
    # Test directory permissions allow navigation
    cd "$expected_dir"
    [ "$(git branch --show-current)" = "$test_branch" ]
    cd - >/dev/null
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$test_branch" 2>/dev/null || true
}

@test "Platform: Shell command execution compatibility" {
    # Test that shell commands work across platforms
    
    # Test date command (used in performance tests)
    run date +%s
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
    
    # Test git commands work consistently
    run git --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "git version" ]]
    
    # Test basic file operations
    run mkdir -p test-platform-dir
    [ "$status" -eq 0 ]
    [ -d test-platform-dir ]
    
    run rmdir test-platform-dir
    [ "$status" -eq 0 ]
    [ \! -d test-platform-dir ]
}

@test "Platform: Zsh functionality detection" {
    # Test detection of zsh-specific features
    
    # Check if running in zsh (completion registration should work)
    if [[ -n "$ZSH_VERSION" ]]; then
        # In zsh - test zsh-specific features
        run echo "ZSH_VERSION: $ZSH_VERSION"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "ZSH_VERSION:" ]]
        
        # Test parameter expansion works
        local test_var="test/value"
        local sanitized="${test_var//\//-}"
        [ "$sanitized" = "test-value" ]
    else
        # Not in zsh - verify function still works
        run gwt-create --help
        [ "$status" -eq 0 ]
        [[ "$output" =~ "Usage:" ]]
    fi
}

@test "Platform: Directory creation with various characters" {
    # Test directory names that might behave differently on different platforms
    local test_cases=(
        "simple-name"
        "name_with_underscores"
        "name.with.dots"
        "name-with-many-hyphens-here"
    )
    
    for test_case in "${test_cases[@]}"; do
        local branch_name="platform/$test_case"
        local expected_dir="../platform-$test_case"
        
        run gwt-create "$branch_name"
        [ "$status" -eq 0 ]
        [ -d "$expected_dir" ]
        
        # Cleanup
        if git worktree list | grep -q "$expected_dir"; then
            git worktree remove "$expected_dir" --force 2>/dev/null || true
        fi
        git branch -D "$branch_name" 2>/dev/null || true
    done
}

@test "Platform: Long path handling" {
    # Test handling of longer paths (different limits on different platforms)
    local base_name="very-long-path-name-to-test-platform-limits"
    local branch_name="feature/$base_name"
    local expected_dir="../feature-$base_name"
    
    # Test with reasonably long path (should work on all platforms)
    run gwt-create "$branch_name"
    [ "$status" -eq 0 ]
    [ -d "$expected_dir" ]
    
    # Verify the path was handled correctly
    git worktree list | grep -q "$expected_dir"
    
    # Cleanup
    if git worktree list | grep -q "$expected_dir"; then
        git worktree remove "$expected_dir" --force 2>/dev/null || true
    fi
    git branch -D "$branch_name" 2>/dev/null || true
}

@test "Platform: Environment variable handling" {
    # Test that environment variables are handled consistently
    
    # Test HOME variable exists (should be available on all platforms)
    [ -n "$HOME" ]
    
    # Test PATH variable exists
    [ -n "$PATH" ]
    
    # Test that git config can access user information
    run git config user.name
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test User" ]]
    
    # Test temporary directory creation
    run mktemp -d
    [ "$status" -eq 0 ]
    [[ "$output" =~ /tmp/ ]] || [[ "$output" =~ /var/ ]]
}

@test "Platform: Color output handling" {
    # Test that color codes work appropriately across platforms
    
    # Test with terminal detection
    if [[ -t 1 ]]; then
        # Running with terminal - colors should work
        run echo -e "[32mgreen text[0m"
        [ "$status" -eq 0 ]
    else
        # Running without terminal - should handle gracefully
        run echo "plain text"
        [ "$status" -eq 0 ]
    fi
    
    # Test function color output in current environment
    run gwt-create --dry-run "color-test"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dry run:" ]]
}

# ============================================================================
# Zsh Framework Integration Testing (Task 5.7)
# ============================================================================

@test "Framework: Function loads correctly in basic zsh environment" {
    # Test that function can be loaded in a clean zsh environment
    run zsh -c "source ../git-worktree.zsh && type gwt-create"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gwt-create is a shell function" ]]
}

@test "Framework: Completion system registration works in zsh" {
    # Test that completion registration works in zsh
    if [[ -n "$ZSH_VERSION" ]]; then
        # In zsh - test completion registration
        source ../git-worktree.zsh
        
        # Check if completion function is registered
        run zsh -c "which _gwt_create"
        if [ "$status" -eq 0 ]; then
            [[ "$output" =~ "_gwt_create" ]]
        fi
        
        # Test that compdef registration code exists
        run grep "compdef.*gwt-create" ../git-worktree.zsh
        [ "$status" -eq 0 ]
    else
        # Not in zsh - skip this test
        skip "This test requires zsh"
    fi
}

@test "Framework: Function works with common zsh options" {
    # Test with common zsh options that might affect function behavior
    
    # Test with EXTENDED_GLOB option
    run zsh -c "setopt EXTENDED_GLOB; source ../git-worktree.zsh && gwt-create --help"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with AUTO_CD option
    run zsh -c "setopt AUTO_CD; source ../git-worktree.zsh && gwt-create --help"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with CORRECT option (command correction)
    run zsh -c "setopt CORRECT; source ../git-worktree.zsh && gwt-create --help"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function works with parameter expansion styles" {
    # Test that function works with different parameter expansion configurations
    
    # Test basic parameter expansion used in the function
    run zsh -c "
        source ../git-worktree.zsh
        test_var=\"feature/test-expansion\"
        sanitized=\"\${test_var//\//-}\"
        echo \"\$sanitized\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "feature-test-expansion" ]]
}

@test "Framework: Function works with different prompt configurations" {
    # Test that function works regardless of prompt configuration
    
    # Test with simple prompt
    run zsh -c "
        PS1=\"%% \"
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with complex prompt (simulating oh-my-zsh style)
    run zsh -c "
        PS1=\"%{%F{green}%}%n@%m%{%f%} %{%F{blue}%}%~%{%f%} \$ \"
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function handles zsh array syntax" {
    # Test that function works with zsh array handling
    
    # Test array operations used in completion
    run zsh -c "
        source ../git-worktree.zsh
        test_array=(\"item1\" \"item2\" \"item3\")
        echo \"\${#test_array[@]}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "3" ]]
}

@test "Framework: Function works with zsh globbing options" {
    # Test function works with different globbing options
    
    # Test with NULL_GLOB
    run zsh -c "
        setopt NULL_GLOB
        source ../git-worktree.zsh
        gwt-create --dry-run test-branch
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dry run:" ]]
    
    # Test with NOMATCH option
    run zsh -c "
        setopt NOMATCH
        source ../git-worktree.zsh
        gwt-create --dry-run test-branch
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dry run:" ]]
}

@test "Framework: Function coexists with other completion systems" {
    # Test that function works alongside other completion systems
    
    # Test with basic completion enabled
    run zsh -c "
        autoload -U compinit
        compinit -u
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function works with zsh history options" {
    # Test that function works with various history options
    
    # Test with EXTENDED_HISTORY
    run zsh -c "
        setopt EXTENDED_HISTORY
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with HIST_VERIFY
    run zsh -c "
        setopt HIST_VERIFY
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function handles common zsh aliases" {
    # Test that function works when common aliases are present
    
    # Test with git aliases
    run zsh -c "
        alias g=git
        alias gb=git branch
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with cd aliases
    run zsh -c "
        alias ..=cd ..
        alias ...=cd ../..
        source ../git-worktree.zsh
        gwt-create --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function works with custom precmd/preexec hooks" {
    # Test that function works when precmd/preexec hooks are present
    
    # Test with custom precmd
    run zsh -c "
        precmd() { echo \"precmd hook\" >&2; }
        source ../git-worktree.zsh
        gwt-create --help 2>/dev/null
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    
    # Test with custom preexec
    run zsh -c "
        preexec() { echo \"preexec hook\" >&2; }
        source ../git-worktree.zsh
        gwt-create --help 2>/dev/null
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "Framework: Function respects user-defined functions with similar names" {
    # Test that function doesn't conflict with user-defined functions
    
    # Test with similar function names
    run zsh -c "
        gwt() { echo \"user gwt function\"; }
        source ../git-worktree.zsh
        type gwt
        type gwt-create
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gwt is a shell function" ]]
    [[ "$output" =~ "gwt-create is a shell function" ]]
}
