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

@test "INTEGRATION: gwt-create with config file copying" {
    # Create config file with test entries
    cat > .gwt-config << EOF
# Test configuration file
CLAUDE.md
.agent-os/
.vscode/
EOF
    
    # Create source files to copy
    echo "# Claude instructions" > CLAUDE.md
    mkdir -p .agent-os
    echo "agent config" > .agent-os/config.yml
    mkdir -p .vscode
    echo '{"setting": "value"}' > .vscode/settings.json
    
    # Create worktree
    run gwt-create feature/config-copy-test
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/feature-config-copy-test" ]
    
    # Verify files were copied
    [ -f "../test-repo-worktrees/feature-config-copy-test/CLAUDE.md" ]
    [ -d "../test-repo-worktrees/feature-config-copy-test/.agent-os" ]
    [ -f "../test-repo-worktrees/feature-config-copy-test/.agent-os/config.yml" ]
    [ -d "../test-repo-worktrees/feature-config-copy-test/.vscode" ]
    [ -f "../test-repo-worktrees/feature-config-copy-test/.vscode/settings.json" ]
    
    # Verify content is correct
    [ "$(cat "../test-repo-worktrees/feature-config-copy-test/CLAUDE.md")" = "# Claude instructions" ]
    [ "$(cat "../test-repo-worktrees/feature-config-copy-test/.agent-os/config.yml")" = "agent config" ]
}

@test "INTEGRATION: gwt-create with glob patterns in config" {
    # Create config file with glob patterns - test files not in git
    cat > .gwt-config << EOF
*.md
dev-*
!dev-excluded.txt
EOF
    
    # Create source files matching patterns (CHANGELOG not in initial commit)
    echo "# CHANGELOG" > CHANGELOG.md
    echo "development config" > dev-config.txt
    echo "excluded content" > dev-excluded.txt
    echo "normal file" > normal.txt
    
    # Don't commit these files - they should be copied by configuration
    
    # Create worktree
    run gwt-create feature/glob-test
    [ "$status" -eq 0 ]
    
    # Verify files matching patterns were copied (except excluded ones)
    [ -f "../test-repo-worktrees/feature-glob-test/README.md" ]  # From git
    [ -f "../test-repo-worktrees/feature-glob-test/CHANGELOG.md" ]  # Copied by config
    [ -f "../test-repo-worktrees/feature-glob-test/dev-config.txt" ]  # Copied by config
    [ ! -f "../test-repo-worktrees/feature-glob-test/dev-excluded.txt" ]  # Should be excluded
    [ ! -f "../test-repo-worktrees/feature-glob-test/normal.txt" ]  # Doesn't match pattern
}

@test "INTEGRATION: gwt-create without config file maintains backward compatibility" {
    # Ensure no config file exists
    [[ ! -f .gwt-config ]]
    
    # Create worktree should work normally without copying any files
    run gwt-create feature/no-config-test
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/feature-no-config-test" ]
    
    # Should still contain git repository files but no extra files
    [ -f "../test-repo-worktrees/feature-no-config-test/.git" ]
    [ -f "../test-repo-worktrees/feature-no-config-test/README.md" ]  # Git files only
}

@test "INTEGRATION: gwt-create handles file copy failures gracefully" {
    # Create config file with non-existent entries
    cat > .gwt-config << EOF
nonexistent-file.txt
CLAUDE.md
nonexistent-dir/
EOF
    
    # Create only one of the configured files
    echo "# Claude instructions" > CLAUDE.md
    
    # Create worktree should succeed despite missing files
    run gwt-create feature/partial-copy-test
    [ "$status" -eq 0 ]
    [ -d "../test-repo-worktrees/feature-partial-copy-test" ]
    
    # Existing file should be copied
    [ -f "../test-repo-worktrees/feature-partial-copy-test/CLAUDE.md" ]
    
    # Non-existent files should be skipped (no error)
    [ ! -f "../test-repo-worktrees/feature-partial-copy-test/nonexistent-file.txt" ]
    [ ! -d "../test-repo-worktrees/feature-partial-copy-test/nonexistent-dir" ]
}

@test "INTEGRATION: gwt-create with config in repository root" {
    # Create config file in repository root
    cat > .gwt-config << EOF
CLAUDE.md
EOF
    echo "# Project instructions" > CLAUDE.md
    
    # Commit the config file and CLAUDE.md so they exist in the repository
    git add .gwt-config CLAUDE.md
    git commit -m "Add config file and CLAUDE.md for root config test"
    
    # Navigate to subdirectory
    mkdir -p src
    cd src
    
    # Should find config in repo root and copy files
    run gwt-create feature/root-config-test
    [ "$status" -eq 0 ]
    
    # Return to repo root to verify
    cd "$TEST_TEMP_DIR/test-repo"
    [ -f "../test-repo-worktrees/feature-root-config-test/CLAUDE.md" ]
    [ "$(cat "../test-repo-worktrees/feature-root-config-test/CLAUDE.md")" = "# Project instructions" ]
}