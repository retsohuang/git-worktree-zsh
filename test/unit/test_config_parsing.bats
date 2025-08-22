#!/usr/bin/env bats

# Unit tests for configuration file parsing functions
# These test the .gwt-config file parsing functionality in isolation

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

@test "UNIT: _gwt_find_config_file finds config in current directory" {
    # Create config file in current directory
    echo ".claude" > .gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    [[ "$output" =~ /.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file falls back to repo root" {
    # Create subdirectory and change to it
    mkdir -p subdir
    cd subdir
    
    # Create config file in repo root
    echo ".claude" > ../.gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    [[ "$output" =~ /.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file returns non-zero when no config exists" {
    run _gwt_find_config_file
    [ "$status" -eq 1 ]
}

@test "UNIT: _gwt_parse_config_file reads simple entries" {
    cat > .gwt-config << EOF
.claude
CLAUDE.md
.vscode/
EOF
    
    run _gwt_parse_config_file .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/" ]]
}

@test "UNIT: _gwt_parse_config_file skips comments and empty lines" {
    cat > .gwt-config << EOF
# This is a comment
.claude

# Another comment
CLAUDE.md
# Final comment
EOF
    
    run _gwt_parse_config_file .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ ! "$output" =~ "This is a comment" ]]
    [[ ! "$output" =~ "Another comment" ]]
    [[ ! "$output" =~ "Final comment" ]]
}

@test "UNIT: _gwt_parse_config_file trims whitespace" {
    cat > .gwt-config << EOF
  .claude  
	CLAUDE.md	
   .vscode/   
EOF
    
    run _gwt_parse_config_file .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/" ]]
    # Should not contain leading/trailing spaces
    [[ ! "$output" =~ "  .claude  " ]]
}

@test "UNIT: _gwt_parse_config_file handles non-existent file" {
    run _gwt_parse_config_file non-existent.config
    [ "$status" -eq 1 ]
}

@test "UNIT: _gwt_expand_config_patterns expands glob patterns" {
    # Create test files
    mkdir -p .vscode .idea
    touch .claude CLAUDE.md
    touch .vscode/settings.json .idea/workspace.xml
    
    # Create config with glob patterns
    cat > .gwt-config << EOF
*.md
.vscode/*
.idea/
EOF
    
    run run_in_zsh _gwt_expand_config_patterns .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/settings.json" ]]
    [[ "$output" =~ ".idea/" ]]
}

@test "UNIT: _gwt_expand_config_patterns handles exclusion patterns" {
    # Create test files
    touch .claude CLAUDE.md README.md
    mkdir -p .vscode
    touch .vscode/settings.json .vscode/temp.log
    
    # Create config with exclusion patterns
    cat > .gwt-config << EOF
*.md
.vscode/*
!README.md
!.vscode/temp.log
EOF
    
    run run_in_zsh _gwt_expand_config_patterns .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/settings.json" ]]
    [[ ! "$output" =~ "README.md" ]]
    [[ ! "$output" =~ ".vscode/temp.log" ]]
}

@test "UNIT: _gwt_expand_config_patterns handles non-existent patterns gracefully" {
    # Create config with patterns that don't match anything
    cat > .gwt-config << EOF
non-existent-*.file
missing-directory/
EOF
    
    run run_in_zsh _gwt_expand_config_patterns .gwt-config
    [ "$status" -eq 0 ]
    # Should succeed but return empty or minimal output
}

@test "UNIT: _gwt_validate_config_entries validates file existence" {
    # Create some test files
    touch .claude CLAUDE.md
    mkdir -p .vscode
    
    # Create config with mix of existing and non-existing files
    cat > .gwt-config << EOF
.claude
CLAUDE.md
.vscode/
non-existent-file
missing-directory/
EOF
    
    run _gwt_validate_config_entries .gwt-config
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/" ]]
    # Non-existent files should be silently filtered out
    [[ ! "$output" =~ "non-existent-file" ]]
    [[ ! "$output" =~ "missing-directory/" ]]
}

@test "UNIT: _gwt_get_config_entries integrates all parsing steps" {
    # Create test files and directories
    touch .claude CLAUDE.md README.md
    mkdir -p .vscode .agent-os
    touch .vscode/settings.json .agent-os/spec.md
    
    # Create comprehensive config file
    cat > .gwt-config << EOF
# Development files
.claude
CLAUDE.md
.agent-os/

# IDE configurations
.vscode/
*.json

# Exclude README
!README.md
EOF
    
    run _gwt_get_config_entries
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".agent-os/" ]]
    [[ "$output" =~ ".vscode/" ]]
    [[ ! "$output" =~ "README.md" ]]
}

@test "UNIT: _gwt_get_config_entries returns empty when no config file" {
    # No config file should exist
    run _gwt_get_config_entries
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# Tests for Task 4.1: Default configuration examples
@test "UNIT: default config example includes common development files" {
    # Create common development files that should be in default config
    touch .claude CLAUDE.md
    mkdir -p .agent-os .vscode .idea
    touch .agent-os/spec.md .vscode/settings.json .idea/workspace.xml
    
    # Create default configuration
    cat > .gwt-config << EOF
# Common development files
.claude
CLAUDE.md
.agent-os/
.vscode/
.idea/
EOF
    
    run _gwt_get_config_entries
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".agent-os/" ]]
    [[ "$output" =~ ".vscode/" ]]
    [[ "$output" =~ ".idea/" ]]
}

@test "UNIT: default config example handles missing optional files gracefully" {
    # Only create some of the default files
    touch .claude CLAUDE.md
    # Intentionally omit .agent-os, .vscode, .idea directories
    
    # Create default configuration with all entries
    cat > .gwt-config << EOF
.claude
CLAUDE.md
.agent-os/
.vscode/
.idea/
EOF
    
    run _gwt_get_config_entries
    [ "$status" -eq 0 ]
    # Should include existing files
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    # Should not fail on missing directories (they'll be filtered out)
}

@test "UNIT: default config example with comments is parsed correctly" {
    # Create test files
    touch .claude CLAUDE.md
    mkdir -p .agent-os .vscode
    
    # Create default config with detailed comments
    cat > .gwt-config << EOF
# Git Worktree Default Configuration
# This file specifies which development files to copy to new worktrees

# Claude AI configuration
.claude

# Project documentation for Claude
CLAUDE.md

# Agent OS configuration and specs
.agent-os/

# VS Code editor settings
.vscode/

# JetBrains IDE settings
.idea/
EOF
    
    run _gwt_get_config_entries
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".agent-os/" ]]
    [[ "$output" =~ ".vscode/" ]]
    # Comments should not appear in output
    [[ ! "$output" =~ "Git Worktree Default" ]]
    [[ ! "$output" =~ "Claude AI configuration" ]]
}

@test "UNIT: _gwt_create_example_config creates default configuration file" {
    # Ensure no config file exists
    [ ! -f .gwt-config ]
    
    # Function should create example config
    run _gwt_create_example_config
    [ "$status" -eq 0 ]
    
    # Config file should now exist
    [ -f .gwt-config ]
    
    # Config should contain expected default entries
    grep -q ".claude" .gwt-config
    grep -q "CLAUDE.md" .gwt-config
    grep -q ".agent-os/" .gwt-config
    grep -q ".vscode/" .gwt-config
    grep -q ".idea/" .gwt-config
    
    # Should contain helpful comments
    grep -q "# " .gwt-config
}

@test "UNIT: _gwt_create_example_config does not overwrite existing config" {
    # Create existing config file
    echo "# Existing config" > .gwt-config
    echo ".custom-file" >> .gwt-config
    
    # Function should not overwrite existing file
    run _gwt_create_example_config
    [ "$status" -eq 1 ]
    
    # Original content should be preserved
    grep -q "Existing config" .gwt-config
    grep -q ".custom-file" .gwt-config
    
    # Should not contain default content
    ! grep -q ".claude" .gwt-config
}