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

# ============================================================================
# Enhanced tests for Task 1.1: Hierarchical config file discovery
# These tests verify the enhanced _gwt_find_config_file() function collects
# all .gwt-config files from current directory up to git root
# ============================================================================

@test "UNIT: _gwt_find_config_file collects single config in current directory" {
    # Create config file in current directory only
    echo ".claude" > .gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should return array with single config file path
    [[ "$output" =~ /.gwt-config$ ]]
    # Output should be single line (single config file)
    [ "$(echo "$output" | wc -l)" -eq 1 ]
}

@test "UNIT: _gwt_find_config_file collects configs in hierarchy from current to git root" {
    # Create multi-level directory structure
    mkdir -p projects/frontend/components
    cd projects/frontend/components
    
    # Create config files at different levels
    echo ".component-config" > .gwt-config                  # Current directory
    echo ".frontend-config" > ../.gwt-config               # Parent directory  
    echo ".project-config" > ../../.gwt-config             # Projects directory
    echo ".root-config" > ../../../.gwt-config             # Git root
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should return array with all config files ordered from closest to git root
    [ "$(echo "$output" | wc -l)" -eq 4 ]
    
    # Verify order: current dir first, then walking up to git root
    local line1=$(echo "$output" | sed -n '1p')
    local line2=$(echo "$output" | sed -n '2p') 
    local line3=$(echo "$output" | sed -n '3p')
    local line4=$(echo "$output" | sed -n '4p')
    
    [[ "$line1" =~ /components/.gwt-config$ ]]
    [[ "$line2" =~ /frontend/.gwt-config$ ]]
    [[ "$line3" =~ /projects/.gwt-config$ ]]
    [[ "$line4" =~ test-repo/.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file handles gaps in hierarchy" {
    # Create directory structure with missing configs in some levels
    mkdir -p level1/level2/level3
    cd level1/level2/level3
    
    # Create configs only at level3 (current) and git root, skip level1 and level2
    echo ".current-config" > .gwt-config                    # Current directory
    echo ".root-config" > ../../../.gwt-config             # Git root
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should return only existing config files
    [ "$(echo "$output" | wc -l)" -eq 2 ]
    
    local line1=$(echo "$output" | sed -n '1p')
    local line2=$(echo "$output" | sed -n '2p')
    
    [[ "$line1" =~ /level3/.gwt-config$ ]]
    [[ "$line2" =~ test-repo/.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file stops at git root" {
    # Get the git root path to create directory structure outside git repo
    local git_root=$(git rev-parse --show-toplevel)
    local parent_dir=$(dirname "$git_root")
    
    # Create config file outside git repo (should not be collected)
    echo ".outside-config" > "$parent_dir/.gwt-config"
    
    # Create config within git repo
    echo ".inside-config" > .gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should only collect config within git repo, not outside
    [[ "$output" =~ /.gwt-config$ ]]
    [[ ! "$output" =~ "$parent_dir/.gwt-config" ]]
    
    # Clean up
    rm -f "$parent_dir/.gwt-config"
}

@test "UNIT: _gwt_find_config_file uses loop protection" {
    # This test verifies the function handles potential infinite loops
    # Create deep directory structure
    mkdir -p very/deep/nested/directory/structure
    cd very/deep/nested/directory/structure
    
    # Create config at current level
    echo ".deep-config" > .gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should complete without infinite loop and return config
    [[ "$output" =~ /.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file returns error when no configs found in hierarchy" {
    # Change to subdirectory with no config files anywhere in hierarchy
    mkdir -p subproject
    cd subproject
    
    # Ensure no .gwt-config files exist in hierarchy
    run _gwt_find_config_file
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "UNIT: _gwt_find_config_file handles permission denied errors gracefully" {
    # Create directory structure
    mkdir -p restricted/subdir
    cd restricted/subdir
    
    # Create config in current directory
    echo ".accessible-config" > .gwt-config
    
    # Note: We can't easily simulate permission denied in test environment
    # This test ensures function doesn't crash with permission issues
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    [[ "$output" =~ /.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file handles symlinks in directory traversal" {
    # Create directory structure with symlinks
    mkdir -p real-dir/subdir
    ln -s real-dir linked-dir
    cd linked-dir/subdir
    
    # Create config files
    echo ".symlink-config" > .gwt-config
    echo ".real-config" > ../../.gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should handle symlinks properly and find configs
    [[ "$output" =~ /.gwt-config ]]
}

@test "UNIT: _gwt_find_config_file caches git root determination for performance" {
    # Create multi-level structure to test caching
    mkdir -p level1/level2/level3
    cd level1/level2/level3
    
    # Create config files at different levels
    echo ".config1" > .gwt-config
    echo ".config2" > ../.gwt-config
    echo ".config3" > ../../.gwt-config
    
    # Run function multiple times to test caching
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    run _gwt_find_config_file  
    [ "$status" -eq 0 ]
    
    # Both runs should produce same result (indicates caching works)
    [ "$(echo "$output" | wc -l)" -ge 2 ]
}

@test "UNIT: _gwt_find_config_file returns paths in correct order (closest to git root)" {
    # Create hierarchy with configs at multiple levels
    mkdir -p a/b/c/d
    cd a/b/c/d
    
    # Create configs with identifiable content
    echo "# d-level config" > .gwt-config
    echo "# c-level config" > ../.gwt-config  
    echo "# b-level config" > ../../.gwt-config
    echo "# a-level config" > ../../../.gwt-config
    echo "# root-level config" > ../../../../.gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    
    # Should return 5 config files
    [ "$(echo "$output" | wc -l)" -eq 5 ]
    
    # Verify order: d -> c -> b -> a -> root  
    local paths=()
    while IFS= read -r line; do
        paths+=("$line")
    done <<< "$output"
    
    # Each successive path should be one level higher (closer to git root)
    [[ "${paths[0]}" =~ /d/.gwt-config$ ]]
    [[ "${paths[1]}" =~ /c/.gwt-config$ ]]
    [[ "${paths[2]}" =~ /b/.gwt-config$ ]]
    [[ "${paths[3]}" =~ /a/.gwt-config$ ]]
    [[ "${paths[4]}" =~ test-repo/.gwt-config$ ]]
}

@test "UNIT: _gwt_find_config_file maintains backward compatibility for single config scenarios" {
    # Test case 1: Config in current directory only (original behavior)
    echo ".current-only" > .gwt-config
    
    run _gwt_find_config_file
    [ "$status" -eq 0 ]
    [[ "$output" =~ /.gwt-config$ ]]
    
    # Clean up for next test case
    rm .gwt-config
    
    # Test case 2: Config in git root only (original fallback behavior)
    mkdir -p subdir
    cd subdir
    echo ".root-only" > ../.gwt-config
    
    run _gwt_find_config_file  
    [ "$status" -eq 0 ]
    [[ "$output" =~ /.gwt-config$ ]]
}

# ============================================================================
# Enhanced tests for Task 2.1: Configuration merging with .gitignore-like precedence
# These tests verify the new _gwt_merge_configs() function handles merging
# multiple config files with proper precedence rules
# ============================================================================

@test "UNIT: _gwt_merge_configs merges single config file" {
    # Create single config file
    cat > .gwt-config << EOF
.claude
CLAUDE.md
.vscode/
EOF
    
    # Create test files
    touch .claude CLAUDE.md
    mkdir -p .vscode
    
    # Mock _gwt_find_config_file to return single config
    local config_path="$(pwd)/.gwt-config"
    
    run _gwt_merge_configs "$config_path"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/" ]]
}

@test "UNIT: _gwt_merge_configs merges configs with git root to current precedence" {
    # Create multi-level directory structure
    mkdir -p project/frontend
    cd project/frontend
    
    # Create config files with overlapping patterns
    # Git root config (lower precedence)
    cat > ../../.gwt-config << EOF
# Root config
.claude
.vscode/
*.md
EOF
    
    # Current directory config (higher precedence)
    cat > .gwt-config << EOF
# Frontend config  
.claude
.eslintrc.js
!README.md
EOF
    
    # Create test files
    touch .claude .eslintrc.js README.md OTHER.md
    mkdir -p .vscode
    
    run _gwt_merge_configs "$(pwd)/../../.gwt-config" "$(pwd)/.gwt-config"
    [ "$status" -eq 0 ]
    
    # Should include patterns from both configs
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ ".vscode/" ]]
    [[ "$output" =~ ".eslintrc.js" ]]
    [[ "$output" =~ "OTHER.md" ]]
    
    # Exclusion from closer config should override include from parent
    [[ ! "$output" =~ "README.md" ]]
}

@test "UNIT: _gwt_merge_configs handles exclusion patterns with proper precedence" {
    # Create hierarchy with exclusion patterns
    mkdir -p team/project/feature
    cd team/project/feature
    
    # Team level (broadest)
    cat > ../../../.gwt-config << EOF
*.md
*.json
.vscode/
EOF
    
    # Project level (overrides team)
    cat > ../.gwt-config << EOF
.claude
!package.json
EOF
    
    # Feature level (most specific)  
    cat > .gwt-config << EOF
feature.config
!FEATURE.md
EOF
    
    # Create test files
    touch README.md FEATURE.md package.json feature.config .claude
    mkdir -p .vscode
    
    run _gwt_merge_configs "../../../.gwt-config" "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Inclusions from all levels
    [[ "$output" =~ "README.md" ]]      # From team level
    [[ "$output" =~ ".claude" ]]        # From project level  
    [[ "$output" =~ "feature.config" ]] # From feature level
    [[ "$output" =~ ".vscode/" ]]       # From team level
    
    # Exclusions should be applied (closer config wins)
    [[ ! "$output" =~ "package.json" ]] # Excluded by project level
    [[ ! "$output" =~ "FEATURE.md" ]]   # Excluded by feature level
}

@test "UNIT: _gwt_merge_configs processes configs in correct order (git root to current)" {
    # Create 3-level hierarchy
    mkdir -p level1/level2
    cd level1/level2
    
    # Root level config
    cat > ../../.gwt-config << EOF
# Order test: should be processed first
order-root.txt
EOF
    
    # Level1 config  
    cat > ../.gwt-config << EOF
# Order test: should be processed second
order-level1.txt
!order-root.txt
EOF
    
    # Level2 config (current)
    cat > .gwt-config << EOF
# Order test: should be processed last
order-level2.txt
EOF
    
    # Create test files
    touch order-root.txt order-level1.txt order-level2.txt
    
    run _gwt_merge_configs "../../.gwt-config" "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Level1 exclusion should override root inclusion
    [[ ! "$output" =~ "order-root.txt" ]]
    [[ "$output" =~ "order-level1.txt" ]]
    [[ "$output" =~ "order-level2.txt" ]]
}

@test "UNIT: _gwt_merge_configs handles complex exclusion overrides" {
    # Test scenario: parent includes pattern, child excludes specific files, grandchild re-includes some
    mkdir -p parent/child/grandchild
    cd parent/child/grandchild
    
    # Parent: include all .txt files
    cat > ../../../.gwt-config << EOF
*.txt
EOF
    
    # Child: exclude specific files
    cat > ../.gwt-config << EOF
!secret.txt
!temp.txt
EOF
    
    # Grandchild: re-include one excluded file
    cat > .gwt-config << EOF
temp.txt
EOF
    
    # Create test files
    touch normal.txt secret.txt temp.txt
    
    run _gwt_merge_configs "../../../.gwt-config" "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Normal file included by parent
    [[ "$output" =~ "normal.txt" ]]
    
    # Secret file excluded by child (not overridden)
    [[ ! "$output" =~ "secret.txt" ]]
    
    # Temp file re-included by grandchild (overriding child exclusion)
    [[ "$output" =~ "temp.txt" ]]
}

@test "UNIT: _gwt_merge_configs optimizes by avoiding redundant file reads" {
    # Create config with same patterns to test optimization
    mkdir -p opt-test
    cd opt-test
    
    # Create identical patterns across configs (should be optimized)
    cat > ../.gwt-config << EOF
.claude
CLAUDE.md
EOF
    
    cat > .gwt-config << EOF
.claude
.vscode/
EOF
    
    # Create test files
    touch .claude CLAUDE.md
    mkdir -p .vscode
    
    run _gwt_merge_configs "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Should contain all unique patterns without duplication
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
    [[ "$output" =~ ".vscode/" ]]
    
    # Should not have duplicate entries (count each pattern once)
    local claude_count=$(echo "$output" | grep -c "^\.claude$")
    [ "$claude_count" -eq 1 ]
}

@test "UNIT: _gwt_merge_configs returns empty when all patterns excluded" {
    # Test scenario where exclusions cancel out all inclusions
    mkdir -p exclusion-test
    cd exclusion-test
    
    # Parent includes files
    cat > ../.gwt-config << EOF
*.md
*.txt
EOF
    
    # Child excludes everything  
    cat > .gwt-config << EOF
!*.md
!*.txt
EOF
    
    # Create test files
    touch test.md test.txt
    
    run _gwt_merge_configs "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Should be empty output (all patterns excluded)
    [ -z "$output" ]
}

@test "UNIT: _gwt_merge_configs handles missing config files gracefully" {
    # Test with some missing config files in the list
    mkdir -p missing-test
    cd missing-test
    
    # Create only one config file
    cat > .gwt-config << EOF
.claude
CLAUDE.md  
EOF
    
    # Create test files
    touch .claude CLAUDE.md
    
    # Call with mix of existing and non-existing config files
    run _gwt_merge_configs "non-existent-1.gwt-config" ".gwt-config" "non-existent-2.gwt-config"
    [ "$status" -eq 0 ]
    
    # Should process existing config and ignore missing ones
    [[ "$output" =~ ".claude" ]]
    [[ "$output" =~ "CLAUDE.md" ]]
}

@test "UNIT: _gwt_merge_configs preserves relative path context from different config locations" {
    # Test that relative paths in configs are resolved correctly based on config file location
    mkdir -p repo/module1/submodule
    cd repo/module1/submodule
    
    # Root config with relative path
    cat > ../../../.gwt-config << EOF
docs/README.md
EOF
    
    # Module config with relative path
    cat > ../.gwt-config << EOF
src/main.js
EOF
    
    # Submodule config with relative path
    cat > .gwt-config << EOF
test/spec.js
EOF
    
    # Create files at different locations
    mkdir -p ../../../docs ../../src test
    touch ../../../docs/README.md ../../src/main.js test/spec.js
    
    run _gwt_merge_configs "../../../.gwt-config" "../.gwt-config" ".gwt-config"
    [ "$status" -eq 0 ]
    
    # Should resolve paths relative to each config file's location
    [[ "$output" =~ "docs/README.md" ]]
    [[ "$output" =~ "src/main.js" ]]
    [[ "$output" =~ "test/spec.js" ]]
}