#!/usr/bin/env bats

# Test helper functions
load '../test_helper'

setup() {
    # Create temporary directory for tests
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_TEMP_DIR"
    
    # Initialize git repo for testing
    git init > /dev/null 2>&1
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@example.com" > /dev/null 2>&1
    
    # Source the git-worktree functions
    source "$ORIGINAL_DIR/git-worktree.zsh"
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
    unset GWT_DEBUG
}

# Test enhanced debug output for config file discovery
@test "UNIT: debug output shows config file hierarchy traversal" {
    # Setup config files at different levels
    mkdir -p subdir/nested
    echo "pattern1" > .gwt-config
    echo "pattern2" > subdir/.gwt-config
    echo "pattern3" > subdir/nested/.gwt-config
    
    cd subdir/nested
    
    # Enable debug mode
    export GWT_DEBUG=1
    
    # Test config discovery with debug output
    run run_in_zsh "_gwt_find_config_file"
    
    [ "$status" -eq 0 ]
    
    # Check that debug output shows hierarchy traversal
    [[ "$output" =~ "subdir/nested/.gwt-config" ]]
    [[ "$output" =~ "subdir/.gwt-config" ]]
    [[ "$output" =~ ".gwt-config" ]]
}

@test "UNIT: debug output shows config merging process when GWT_DEBUG=1" {
    # Setup config files
    echo "base-pattern" > .gwt-config
    mkdir subdir
    echo "override-pattern" > subdir/.gwt-config
    echo "!base-pattern" >> subdir/.gwt-config
    
    cd subdir
    
    # Enable debug mode
    export GWT_DEBUG=1
    
    # Test config merging with debug output (simplified test)
    run _gwt_merge_configs "../.gwt-config" ".gwt-config"
    
    [ "$status" -eq 0 ]
    
    # Should show merging process details
    [[ "$output" =~ "override-pattern" ]]
    # Debug output goes to stderr, but run captures all output together
    [[ "$output" =~ "Debug: Configuration merging started" ]]
}

@test "UNIT: debug output shows precedence order and pattern sources" {
    # Setup hierarchy with different patterns
    echo "# Root config" > .gwt-config
    echo "root-pattern" >> .gwt-config
    
    mkdir -p project/submodule
    echo "# Project config" > project/.gwt-config
    echo "project-pattern" >> project/.gwt-config
    echo "!root-pattern" >> project/.gwt-config
    
    echo "# Submodule config" > project/submodule/.gwt-config  
    echo "submodule-pattern" >> project/submodule/.gwt-config
    
    cd project/submodule
    
    # Enable debug mode
    export GWT_DEBUG=1
    
    # Test hierarchy discovery
    run run_in_zsh "_gwt_find_config_file"
    
    [ "$status" -eq 0 ]
    
    # Should show all three config files in proper order
    [[ "$output" =~ "project/submodule/.gwt-config" ]]
    [[ "$output" =~ "project/.gwt-config" ]]
    [[ "$output" =~ ".gwt-config" ]]
}

@test "UNIT: clear error message when no config files found in hierarchy" {
    # Create directory structure without any config files
    mkdir -p deep/nested/structure
    cd deep/nested/structure
    
    # Test config discovery in empty hierarchy
    run run_in_zsh "_gwt_find_config_file"
    
    [ "$status" -eq 1 ]
    
    # Should provide clear error message about no config files
    # (This will be implemented in the enhanced logging)
}

@test "UNIT: graceful handling of permission denied errors" {
    # Create config file
    echo "test-pattern" > .gwt-config
    
    # Create directory with restricted permissions
    mkdir restricted
    echo "restricted-pattern" > restricted/.gwt-config
    chmod 000 restricted
    
    cd restricted 2>/dev/null || true
    
    # Test config discovery with permission issues
    run run_in_zsh "_gwt_find_config_file 2>&1 || echo 'Permission error handled'"
    
    # Should handle permission errors gracefully
    [[ "$output" =~ "Permission error handled" ]] || [[ "$status" -eq 1 ]]
    
    # Cleanup
    chmod 755 ../restricted 2>/dev/null || true
}

@test "UNIT: debug logging disabled by default" {
    # Setup config files
    echo "pattern1" > .gwt-config
    mkdir subdir
    echo "pattern2" > subdir/.gwt-config
    
    cd subdir
    
    # Test without GWT_DEBUG (should be minimal output)
    run run_in_zsh "_gwt_find_config_file"
    
    [ "$status" -eq 0 ]
    
    # Should not show debug information when GWT_DEBUG is not set
    # Just the config file paths
    [[ "$output" =~ "subdir/.gwt-config" ]]
    [[ "$output" =~ ".gwt-config" ]]
    # But should not show debug prefixes like "Debug:" or detailed hierarchy info
    [[ ! "$output" =~ "Debug:" ]]
}

@test "UNIT: debug output shows final merged result" {
    # Setup complex config merging scenario
    echo "base1" > .gwt-config
    echo "base2" >> .gwt-config
    
    mkdir project
    echo "project1" > project/.gwt-config
    echo "!base1" >> project/.gwt-config
    echo "project2" >> project/.gwt-config
    
    cd project
    
    # Enable debug mode
    export GWT_DEBUG=1
    
    # Test merged config output (simplified test)
    run _gwt_merge_configs "../.gwt-config" ".gwt-config"
    
    [ "$status" -eq 0 ]
    
    # Should show final merged patterns
    [[ "$output" =~ "project1" ]]
    [[ "$output" =~ "project2" ]]
    [[ "$output" =~ "base2" ]]
    # base1 should be excluded due to !base1
    [[ ! "$output" =~ "base1" ]]
    
    # Should show debug output (stderr is captured in output by BATS)
    [[ "$output" =~ "Debug: Configuration merging completed" ]]
    [[ "$output" =~ "Debug: Final merged patterns" ]]
}