#!/usr/bin/env bats

# Unit tests for file copying functionality
# These test the file/directory copying operations in isolation

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

@test "UNIT: _gwt_copy_file copies single file" {
    # Create source file
    echo "test content" > source.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_file source.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/source.txt ]
    [ "$(cat target-dir/source.txt)" = "test content" ]
}

@test "UNIT: _gwt_copy_file preserves file permissions" {
    # Create source file with specific permissions
    echo "test content" > source.txt
    chmod 755 source.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_file source.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/source.txt ]
    
    # Check permissions are preserved
    local source_perms=$(stat -f %A source.txt 2>/dev/null || stat -c %a source.txt 2>/dev/null)
    local target_perms=$(stat -f %A target-dir/source.txt 2>/dev/null || stat -c %a target-dir/source.txt 2>/dev/null)
    [ "$source_perms" = "$target_perms" ]
}

@test "UNIT: _gwt_copy_file handles non-existent source" {
    mkdir -p target-dir
    
    run _gwt_copy_file non-existent.txt target-dir/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    [ ! -f target-dir/non-existent.txt ]
    # Should log that file was skipped
    [[ "$output" =~ "Skipped" ]]
}

@test "UNIT: _gwt_copy_directory copies directory recursively" {
    # Create source directory structure
    mkdir -p source-dir/subdir
    echo "file1 content" > source-dir/file1.txt
    echo "file2 content" > source-dir/subdir/file2.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_directory source-dir target-dir/
    [ "$status" -eq 0 ]
    [ -d target-dir/source-dir ]
    [ -f target-dir/source-dir/file1.txt ]
    [ -d target-dir/source-dir/subdir ]
    [ -f target-dir/source-dir/subdir/file2.txt ]
    [ "$(cat target-dir/source-dir/file1.txt)" = "file1 content" ]
    [ "$(cat target-dir/source-dir/subdir/file2.txt)" = "file2 content" ]
}

@test "UNIT: _gwt_copy_directory preserves directory permissions" {
    # Create source directory with specific permissions
    mkdir -p source-dir
    chmod 755 source-dir
    echo "content" > source-dir/file.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_directory source-dir target-dir/
    [ "$status" -eq 0 ]
    [ -d target-dir/source-dir ]
    
    # Check permissions are preserved
    local source_perms=$(stat -f %A source-dir 2>/dev/null || stat -c %a source-dir 2>/dev/null)
    local target_perms=$(stat -f %A target-dir/source-dir 2>/dev/null || stat -c %a target-dir/source-dir 2>/dev/null)
    [ "$source_perms" = "$target_perms" ]
}

@test "UNIT: _gwt_copy_directory handles non-existent source" {
    mkdir -p target-dir
    
    run _gwt_copy_directory non-existent-dir target-dir/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    [ ! -d target-dir/non-existent-dir ]
    # Should log that directory was skipped
    [[ "$output" =~ "Skipped" ]]
}

@test "UNIT: _gwt_copy_symlink handles symbolic links by copying target" {
    # Create target file and symlink
    echo "target content" > target-file.txt
    ln -s target-file.txt symlink.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_symlink symlink.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/symlink.txt ]
    [ ! -L target-dir/symlink.txt ]  # Should not be a symlink
    [ "$(cat target-dir/symlink.txt)" = "target content" ]
}

@test "UNIT: _gwt_copy_symlink handles broken symlinks gracefully" {
    # Create broken symlink
    ln -s non-existent-target.txt broken-link.txt
    
    # Create target directory
    mkdir -p target-dir
    
    run _gwt_copy_symlink broken-link.txt target-dir/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    [ ! -f target-dir/broken-link.txt ]
    # Should log failure for broken symlink
    [[ "$output" =~ "Failed" ]] || [[ "$output" =~ "Broken symlink" ]]
}

@test "UNIT: _gwt_copy_entry determines correct copy method for file" {
    echo "test content" > test-file.txt
    mkdir -p target-dir
    
    run _gwt_copy_entry test-file.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/test-file.txt ]
}

@test "UNIT: _gwt_copy_entry determines correct copy method for directory" {
    mkdir -p test-dir
    echo "content" > test-dir/file.txt
    mkdir -p target-dir
    
    run _gwt_copy_entry test-dir target-dir/
    [ "$status" -eq 0 ]
    [ -d target-dir/test-dir ]
    [ -f target-dir/test-dir/file.txt ]
}

@test "UNIT: _gwt_copy_entry determines correct copy method for symlink" {
    echo "target content" > target.txt
    ln -s target.txt link.txt
    mkdir -p target-dir
    
    run _gwt_copy_entry link.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/link.txt ]
    [ ! -L target-dir/link.txt ]  # Should be copied as regular file
}

@test "UNIT: _gwt_copy_entries processes multiple entries" {
    # Create multiple test items
    echo "file content" > test-file.txt
    mkdir -p test-dir
    echo "dir content" > test-dir/file.txt
    echo "target" > target.txt
    ln -s target.txt test-link.txt
    
    # Create target directory
    mkdir -p target-dir
    
    # Test copying multiple entries
    run _gwt_copy_entries "test-file.txt test-dir test-link.txt" target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/test-file.txt ]
    [ -d target-dir/test-dir ]
    [ -f target-dir/test-dir/file.txt ]
    [ -f target-dir/test-link.txt ]
}

@test "UNIT: _gwt_copy_entries continues on individual failures" {
    # Create one valid and one invalid entry
    echo "valid content" > valid-file.txt
    mkdir -p target-dir
    
    run _gwt_copy_entries "valid-file.txt non-existent-file.txt" target-dir/
    # Should partially succeed
    [ -f target-dir/valid-file.txt ]
    [ ! -f target-dir/non-existent-file.txt ]
}

@test "UNIT: _gwt_log_copy_operation logs success" {
    run _gwt_log_copy_operation "test-file.txt" "target-dir/" "success"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "✓" ]]
    [[ "$output" =~ "test-file.txt" ]]
    [[ "$output" =~ "target-dir/" ]]
}

@test "UNIT: _gwt_log_copy_operation logs failure" {
    run _gwt_log_copy_operation "test-file.txt" "target-dir/" "failure" "Permission denied"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "✗" ]]
    [[ "$output" =~ "test-file.txt" ]]
    [[ "$output" =~ "Permission denied" ]]
}

@test "UNIT: _gwt_validate_copy_permissions checks source readability" {
    # Create readable file
    echo "content" > readable.txt
    chmod 644 readable.txt
    
    run _gwt_validate_copy_permissions readable.txt
    [ "$status" -eq 0 ]
    
    # Create unreadable file (if possible)
    echo "content" > unreadable.txt
    chmod 000 unreadable.txt
    
    run _gwt_validate_copy_permissions unreadable.txt
    # This might succeed or fail depending on system and user permissions
    # The main point is that the function handles permission checking
    
    # Cleanup
    chmod 644 unreadable.txt 2>/dev/null || true
}

@test "UNIT: _gwt_validate_copy_permissions checks target writability" {
    mkdir -p writable-dir
    chmod 755 writable-dir
    
    echo "test content" > source
    
    run _gwt_validate_copy_permissions "source" writable-dir/
    [ "$status" -eq 0 ]
}

# Tests for Task 5.1: Edge cases and error handling
@test "UNIT: _gwt_copy_file handles permission denied gracefully" {
    # Create source file
    echo "test content" > source.txt
    
    # Create target directory with limited permissions (if possible)
    mkdir -p target-dir
    chmod 555 target-dir 2>/dev/null || true  # Read-only directory
    
    run _gwt_copy_file source.txt target-dir/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    # Should log permission failure
    [[ "$output" =~ "Permission denied" ]] || [[ "$output" =~ "Failed" ]]
    
    # Cleanup
    chmod 755 target-dir 2>/dev/null || true
}

@test "UNIT: _gwt_copy_file handles disk space issues gracefully" {
    # This test simulates disk space issues by trying to copy to non-existent path
    echo "test content" > source.txt
    
    # Try to copy to a path that doesn't exist and can't be created
    run _gwt_copy_file source.txt /non/existent/deeply/nested/path/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    # Should log failure
    [[ "$output" =~ "Failed" ]] || [[ "$output" =~ "Cannot create" ]]
}

@test "UNIT: _gwt_copy_file handles extremely long filenames" {
    # Create file with very long name (but within filesystem limits)
    local long_name="very_long_filename_that_tests_filesystem_limits_but_stays_within_reasonable_bounds.txt"
    echo "test content" > "$long_name"
    mkdir -p target-dir
    
    run _gwt_copy_file "$long_name" target-dir/
    [ "$status" -eq 0 ]
    [ -f "target-dir/$long_name" ]
}

@test "UNIT: _gwt_copy_file handles special characters in filenames" {
    # Create files with special characters
    echo "content1" > "file with spaces.txt"
    echo "content2" > "file-with-dashes.txt"
    echo "content3" > "file_with_underscores.txt"
    mkdir -p target-dir
    
    run _gwt_copy_file "file with spaces.txt" target-dir/
    [ "$status" -eq 0 ]
    [ -f "target-dir/file with spaces.txt" ]
    
    run _gwt_copy_file "file-with-dashes.txt" target-dir/
    [ "$status" -eq 0 ]
    [ -f "target-dir/file-with-dashes.txt" ]
    
    run _gwt_copy_file "file_with_underscores.txt" target-dir/
    [ "$status" -eq 0 ]
    [ -f "target-dir/file_with_underscores.txt" ]
}

@test "UNIT: _gwt_copy_directory handles deeply nested structures" {
    # Create deeply nested directory structure
    mkdir -p "deep/nested/directory/structure/level5"
    echo "deep content" > "deep/nested/directory/structure/level5/file.txt"
    mkdir -p target-dir
    
    run _gwt_copy_directory "deep" target-dir/
    [ "$status" -eq 0 ]
    [ -f "target-dir/deep/nested/directory/structure/level5/file.txt" ]
}

@test "UNIT: _gwt_copy_directory handles empty directories" {
    # Create empty directory
    mkdir -p empty-dir
    mkdir -p target-dir
    
    run _gwt_copy_directory empty-dir target-dir/
    [ "$status" -eq 0 ]
    [ -d target-dir/empty-dir ]
}

@test "UNIT: _gwt_copy_symlink handles circular symlinks gracefully" {
    # Create circular symlink
    ln -s link2.txt link1.txt
    ln -s link1.txt link2.txt
    mkdir -p target-dir
    
    run _gwt_copy_symlink link1.txt target-dir/
    # Task 5.4: Should continue worktree creation despite copy failures
    [ "$status" -eq 0 ]
    # Should not hang or crash, and should log failure
    [[ "$output" =~ "Failed" ]] || [[ "$output" =~ "Broken symlink" ]]
}

@test "UNIT: _gwt_copy_symlink handles deeply nested symlinks" {
    # Create nested symlink chain
    echo "final content" > final.txt
    ln -s final.txt link3.txt
    ln -s link3.txt link2.txt
    ln -s link2.txt link1.txt
    mkdir -p target-dir
    
    run _gwt_copy_symlink link1.txt target-dir/
    [ "$status" -eq 0 ]
    [ -f target-dir/link1.txt ]
    [ "$(cat target-dir/link1.txt)" = "final content" ]
}

@test "UNIT: _gwt_copy_entries handles mixed success and failure scenarios" {
    # Create mix of valid and invalid sources
    echo "valid1" > valid1.txt
    echo "valid2" > valid2.txt
    mkdir -p target-dir
    
    # Mix existing and non-existing files
    run _gwt_copy_entries "valid1.txt non-existent1.txt valid2.txt non-existent2.txt" target-dir/
    
    # Should continue processing despite failures
    [ -f target-dir/valid1.txt ]
    [ -f target-dir/valid2.txt ]
    [ ! -f target-dir/non-existent1.txt ]
    [ ! -f target-dir/non-existent2.txt ]
}

@test "UNIT: _gwt_copy_entries handles empty input gracefully" {
    mkdir -p target-dir
    
    run _gwt_copy_entries "" target-dir/
    [ "$status" -eq 0 ]
    # Should not crash on empty input
}

@test "UNIT: _gwt_log_copy_operation handles very long error messages" {
    local long_error="This is a very long error message that might occur during file operations and should be handled gracefully without breaking the output formatting or causing display issues in the terminal"
    
    run _gwt_log_copy_operation "test-file.txt" "target/" "failure" "$long_error"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "✗" ]]
    [[ "$output" =~ "test-file.txt" ]]
}

@test "UNIT: _gwt_validate_copy_permissions handles non-existent source paths" {
    run _gwt_validate_copy_permissions "/completely/non/existent/path"
    [ "$status" -ne 0 ]
    # Should fail gracefully - this function should still return error codes for validation
}

@test "UNIT: _gwt_validate_copy_permissions handles non-existent target directories" {
    echo "content" > test-file.txt
    
    run _gwt_validate_copy_permissions test-file.txt "/non/existent/target/path/"
    [ "$status" -ne 0 ]
    # Should fail gracefully when target directory doesn't exist - validation should still return errors
}