#!/usr/bin/env zsh

# Git Worktree Zsh Function Suite
# A comprehensive zsh function suite for managing git worktrees
# Version: 1.0.0

# gwt-create: Create a new git worktree with branch in organized folder structure
# Usage: gwt-create <branch-name> [target-directory]
# Creates worktree in "{project-name}-worktrees/{branch-name}" pattern
function gwt-create() {
    local branch_name=""
    local target_dir=""
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                _gwt_show_usage
                return 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                _gwt_show_usage
                return 1
                ;;
            *)
                if [[ -z "$branch_name" ]]; then
                    branch_name="$1"
                elif [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    echo "Error: Too many arguments" >&2
                    _gwt_show_usage
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Show usage if no branch name provided
    if [[ -z "$branch_name" ]]; then
        echo "Error: Branch name cannot be empty" >&2
        echo "Suggestion: Provide a valid branch name, for example: gwt-create feature/my-feature" >&2
        _gwt_show_usage
        return 1
    fi
    
    # Validate branch name
    if ! _gwt_validate_branch_name "$branch_name"; then
        return 1
    fi
    
    # Check if we're in a git repository
    if ! _gwt_check_git_repo; then
        return 1
    fi
    
    # Check if we're inside a worktree
    if ! _gwt_check_not_in_worktree; then
        return 1
    fi
    
    # Determine branch creation/checkout strategy
    local strategy
    strategy=$(_gwt_determine_branch_strategy "$branch_name")
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine branch strategy" >&2
        return 1
    fi
    
    # Resolve target directory path
    local target_path
    target_path=$(_gwt_resolve_target_directory "$branch_name" "$target_dir")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Task 4.7: Validate filesystem access and requirements
    if ! _gwt_validate_filesystem_access "$target_path"; then
        return 1
    fi
    
    if ! _gwt_validate_path_length "$target_path"; then
        return 1
    fi
    
    if ! _gwt_check_disk_space "$target_path"; then
        return 1
    fi
    
    if [[ "$dry_run" == true ]]; then
        echo "Dry run: Would create worktree '$target_path' for branch '$branch_name'"
        echo "Strategy: $strategy"
        return 0
    fi
    
    # Task 4.4: Show progress indicator
    _gwt_show_progress "Creating worktree '$target_path' for branch '$branch_name'..."
    
    # Create the worktree with error handling and cleanup
    if ! _gwt_create_worktree "$branch_name" "$target_path" "$strategy"; then
        # Task 4.6: Cleanup on failure
        _gwt_cleanup_failed_worktree "$target_path" "$branch_name"
        return 1
    fi
    
    # Navigate to the new worktree directory
    _gwt_show_progress "Navigating to worktree directory..."
    cd "$target_path" || {
        _gwt_warning "Worktree created successfully but failed to navigate to directory"
        echo "You can manually navigate to: $target_path" >&2
        return 0
    }
    
    # Task 4.5: Success message with color
    _gwt_success "Successfully created and navigated to worktree for branch '$branch_name'"
    return 0
}

# Show usage information
function _gwt_show_usage() {
    cat << EOF
Usage: gwt-create <branch-name> [target-directory]

Create a new git worktree with the specified branch.

Arguments:
  branch-name       Name of the branch to create or checkout
  target-directory  Directory name for the worktree (defaults to branch name)

Options:
  -h, --help       Show this help message
  --dry-run        Show what would be done without executing

Examples:
  gwt-create feature/auth
  gwt-create bugfix-123 bugfix
  gwt-create --dry-run test-branch

The worktree will be created in a dedicated "{project-name}-worktrees/" folder.
EOF
}

# Validate branch name according to git naming rules
function _gwt_validate_branch_name() {
    local branch_name="$1"
    
    # Check if branch name is empty
    if [[ -z "$branch_name" ]]; then
        echo "Error: Branch name cannot be empty" >&2
        return 1
    fi
    
    # Check branch name length (git has practical limits)
    if [[ "${#branch_name}" -gt 200 ]]; then
        echo "Error: Branch name too long: ${#branch_name} characters (maximum: 200)" >&2
        echo "Suggestion: Use a shorter, more concise branch name" >&2
        return 1
    fi
    
    # Check for invalid characters and patterns
    # Git branch naming rules: comprehensive validation
    
    # Cannot contain spaces
    if [[ "$branch_name" =~ [[:space:]] ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot contain spaces" >&2
        echo "Suggestion: Use hyphens or underscores instead of spaces (e.g., 'feature-auth' or 'feature_auth')" >&2
        return 1
    fi
    
    # Cannot start with dash or dot
    if [[ "$branch_name" =~ ^[-\.] ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot start with dash or dot" >&2
        echo "Suggestion: Start the branch name with a letter or number (e.g., 'feature-name' or 'v1.0')" >&2
        return 1
    fi
    
    # Cannot end with dot or .lock
    if [[ "$branch_name" == *"." ]] || [[ "$branch_name" == *".lock" ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot end with dot or .lock" >&2
        return 1
    fi
    
    # Cannot contain ASCII control characters, DEL, or specific special characters
    # Check for specific invalid characters
    if [[ "$branch_name" == *"@"* ]] || [[ "$branch_name" == *"#"* ]] || [[ "$branch_name" == *"$"* ]] || [[ "$branch_name" == *"^"* ]] || [[ "$branch_name" == *"~"* ]] || [[ "$branch_name" == *":"* ]] || [[ "$branch_name" == *"?"* ]] || [[ "$branch_name" == *"*"* ]] || [[ "$branch_name" == *"["* ]] || [[ "$branch_name" == *"]"* ]] || [[ "$branch_name" == *"\\"* ]]; then
        echo "Error: Invalid branch name '$branch_name' - contains invalid characters" >&2
        return 1
    fi
    
    # Cannot contain consecutive dots
    if [[ "$branch_name" == *".."* ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot contain consecutive dots" >&2
        return 1
    fi
    
    # Cannot contain slash-dot or dot-slash sequences
    if [[ "$branch_name" == *"/."* ]] || [[ "$branch_name" == *"./"* ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot contain sequences like '/.' or './'" >&2
        return 1
    fi
    
    # Cannot be exactly '@'
    if [[ "$branch_name" == "@" ]]; then
        echo "Error: Invalid branch name '$branch_name' - cannot be exactly '@'" >&2
        return 1
    fi
    
    return 0
}

# Check if current directory is inside a git repository
function _gwt_check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not a git repository (or any of the parent directories)" >&2
        echo "Please run this command from within a git repository." >&2
        return 1
    fi
    return 0
}

# Check if current directory is not inside a worktree
function _gwt_check_not_in_worktree() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    
    # If git-dir path contains ".git/worktrees/", we're in a worktree
    if [[ "$git_dir" =~ \.git/worktrees/ ]]; then
        echo "Error: Cannot create worktree from inside another worktree" >&2
        echo "Please run this command from the main repository directory." >&2
        echo "Suggestion: Use 'cd \$(git rev-parse --show-superproject-working-tree || git rev-parse --show-toplevel)' to navigate to the main repository." >&2
        return 1
    fi
    
    # Additional check: verify we're not in a worktree by checking git-common-dir
    # Only trigger if the git-dir is actually in a worktrees subdirectory
    local common_dir
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    
    if [[ -n "$common_dir" && "$git_dir" != "$common_dir" && "$git_dir" =~ /\.git/worktrees/ ]]; then
        echo "Error: Cannot create worktree from inside another worktree" >&2
        echo "Current location appears to be a git worktree based on common-dir detection." >&2
        echo "Suggestion: Navigate to the main repository directory before creating worktrees." >&2
        return 1
    fi
    
    return 0
}

# Check if a branch exists locally
function _gwt_branch_exists_locally() {
    local branch_name="$1"
    
    if [[ -z "$branch_name" ]]; then
        return 1
    fi
    
    # Use git branch --list to check if branch exists locally
    # The output will be empty if branch doesn't exist
    if git branch --list "$branch_name" | grep -q "^[* ] *$branch_name$"; then
        return 0
    else
        return 1
    fi
}

# Check if a branch exists on a remote
function _gwt_branch_exists_remotely() {
    local remote_name="$1"
    local branch_name="$2"
    
    if [[ -z "$remote_name" || -z "$branch_name" ]]; then
        return 1
    fi
    
    # Use git ls-remote to check if branch exists on remote
    # Suppress error output and check exit status
    if git ls-remote --heads "$remote_name" "$branch_name" 2>/dev/null | grep -q "refs/heads/$branch_name$"; then
        return 0
    else
        return 1
    fi
}

# Determine the branch creation/checkout strategy
function _gwt_determine_branch_strategy() {
    local branch_name="$1"
    local strategy=""
    
    if [[ -z "$branch_name" ]]; then
        echo "create-new"
        return 0
    fi
    
    # Check if branch exists locally
    if _gwt_branch_exists_locally "$branch_name"; then
        strategy="checkout-local"
    else
        # Check if branch exists on any remote
        local remotes
        remotes=($(git remote 2>/dev/null))
        
        for remote in "${remotes[@]}"; do
            if _gwt_branch_exists_remotely "$remote" "$branch_name"; then
                strategy="checkout-remote:$remote"
                break
            fi
        done
        
        # If not found locally or remotely, create new branch
        if [[ -z "$strategy" ]]; then
            strategy="create-new"
        fi
    fi
    
    echo "$strategy"
    return 0
}

# Sanitize branch name for filesystem compatibility
function _gwt_sanitize_directory_name() {
    local branch_name="$1"
    
    if [[ -z "$branch_name" ]]; then
        echo ""
        return 1
    fi
    
    # Replace slashes with dashes for directory names
    # This maintains readability while being filesystem-safe
    local sanitized_name="${branch_name//\//-}"
    
    # Remove any leading or trailing dashes
    sanitized_name="${sanitized_name#-}"
    sanitized_name="${sanitized_name%-}"
    
    # Ensure we don't have multiple consecutive dashes (repeat until no more changes)
    while [[ "$sanitized_name" =~ -- ]]; do
        sanitized_name="${sanitized_name//--/-}"
    done
    
    # Remove any leading or trailing dashes again after consecutive dash removal
    sanitized_name="${sanitized_name#-}"
    sanitized_name="${sanitized_name%-}"
    
    # Handle edge case of empty result
    if [[ -z "$sanitized_name" ]]; then
        sanitized_name="branch"
    fi
    
    echo "$sanitized_name"
    return 0
}

# Check for directory conflicts before creating worktree
function _gwt_check_directory_conflict() {
    local target_path="$1"
    
    if [[ -z "$target_path" ]]; then
        return 1
    fi
    
    # Check if path already exists (file or directory)
    if [[ -e "$target_path" ]]; then
        if [[ -d "$target_path" ]]; then
            echo "Error: Directory '$target_path' already exists" >&2
            echo "Please choose a different directory name or remove the existing directory." >&2
        else
            echo "Error: File '$target_path' already exists and conflicts with target directory" >&2
            echo "Please choose a different directory name or remove the existing file." >&2
        fi
        return 1
    fi
    
    return 0
}

# CORE-FEATURE: Organized worktree structure
# DO NOT REMOVE: This implements the main value proposition
# Resolve the target directory path for worktree creation in organized structure
# Creates path in pattern: "{parent-dir}/{project-name}-worktrees/{branch-name}"
function _gwt_resolve_target_directory() {
    local branch_name="$1"
    local custom_target="$2"
    
    if [[ -z "$branch_name" ]]; then
        return 1
    fi
    
    # Get the current project information
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    
    if [[ -z "$repo_root" ]]; then
        echo "Error: Could not determine git repository root" >&2
        return 1
    fi
    
    # CORE-FEATURE: Extract project name and parent directory for organized structure
    local project_name
    project_name=$(basename "$repo_root")
    local parent_dir
    parent_dir=$(dirname "$repo_root")
    
    # CORE-FEATURE: Construct worktree container path - this creates the organized structure
    # DO NOT REMOVE: This line creates the "{project-name}-worktrees" directory pattern
    local worktree_container="${parent_dir}/${project_name}-worktrees"
    
    # Determine directory name
    local dir_name
    if [[ -n "$custom_target" ]]; then
        # Handle relative paths in custom target
        if [[ "$custom_target" =~ ^\.\./ ]]; then
            # Remove leading ../ and use the rest as directory name
            dir_name="${custom_target#../}"
        else
            dir_name="$custom_target"
        fi
    else
        # Sanitize branch name for directory use
        dir_name=$(_gwt_sanitize_directory_name "$branch_name")
    fi
    
    # CORE-FEATURE: Construct final worktree path within the organized structure
    # DO NOT REMOVE: This creates the organized directory structure
    local target_path="${worktree_container}/${dir_name}"
    
    echo "$target_path"
    return 0
}

# Create a git worktree based on the strategy determined
function _gwt_create_worktree() {
    local branch_name="$1"
    local target_path="$2"
    local strategy="$3"
    
    if [[ -z "$branch_name" || -z "$target_path" || -z "$strategy" ]]; then
        echo "Error: Missing required parameters for worktree creation" >&2
        return 1
    fi
    
    # Check for directory conflicts before proceeding
    if ! _gwt_check_directory_conflict "$target_path"; then
        return 1
    fi
    
    # CORE-FEATURE: Ensure worktree container directory exists
    # DO NOT REMOVE: This auto-creates the organized directory structure
    local container_dir
    container_dir=$(dirname "$target_path")
    
    if [[ ! -d "$container_dir" ]]; then
        _gwt_show_progress "Creating worktree container directory '$container_dir'..."
        if ! mkdir -p "$container_dir" 2>/dev/null; then
            _gwt_error "Failed to create worktree container directory '$container_dir'"
            echo "Possible causes: Filesystem permissions or insufficient disk space" >&2
            echo "Suggestion: Check directory permissions or try creating the directory manually" >&2
            return 1
        fi
    fi
    
    # Execute git worktree add based on strategy
    case "$strategy" in
        "create-new")
            # Create worktree with new branch from current HEAD
            _gwt_show_progress "Creating new branch '$branch_name'..."
            if ! git worktree add -b "$branch_name" "$target_path" 2>/dev/null; then
                _gwt_error "Failed to create worktree with new branch '$branch_name'"
                echo "Possible causes: Branch already exists, filesystem permissions, or git repository issues" >&2
                echo "Suggestion: Check 'git branch -a' to see existing branches or try 'git status' to check repository health" >&2
                return 1
            fi
            ;;
        "checkout-local")
            # Create worktree from existing local branch
            _gwt_show_progress "Checking out existing local branch '$branch_name'..."
            if ! git worktree add "$target_path" "$branch_name" 2>/dev/null; then
                _gwt_error "Failed to create worktree from local branch '$branch_name'"
                echo "Possible causes: Branch is checked out elsewhere, filesystem issues, or corrupted branch" >&2
                echo "Suggestion: Check 'git worktree list' to see where the branch might be in use" >&2
                return 1
            fi
            ;;
        checkout-remote:*)
            # Extract remote name from strategy
            local remote_name="${strategy#checkout-remote:}"
            
            # Create worktree from remote branch (creates local tracking branch)
            _gwt_show_progress "Creating local tracking branch for remote '$remote_name/$branch_name'..."
            if ! git worktree add -b "$branch_name" "$target_path" "$remote_name/$branch_name" 2>/dev/null; then
                _gwt_error "Failed to create worktree from remote branch '$remote_name/$branch_name'"
                echo "Possible causes: Remote branch doesn't exist, network issues, or local branch conflicts" >&2
                echo "Suggestion: Try 'git fetch $remote_name' to update remote references or verify branch exists with 'git ls-remote $remote_name'" >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown worktree creation strategy '$strategy'" >&2
            return 1
            ;;
    esac
    
    # Verify worktree was created successfully
    if [[ ! -d "$target_path" ]]; then
        _gwt_error "Worktree directory was not created successfully"
        echo "Suggestion: Check filesystem permissions and available space" >&2
        return 1
    fi
    
    _gwt_success "Successfully created worktree '$target_path' for branch '$branch_name'"
    return 0
}

# Task 4.4: Progress indicator utilities
function _gwt_show_progress() {
    local message="$1"
    local color="$2"
    
    if [[ -t 1 ]]; then  # Check if output is to terminal
        case "$color" in
            "green") echo -e "\033[32m🔧 $message\033[0m" ;;
            "yellow") echo -e "\033[33m⚠️  $message\033[0m" ;;
            "red") echo -e "\033[31m❌ $message\033[0m" ;;
            *) echo "🔧 $message" ;;
        esac
    else
        echo "$message"
    fi
}

# Task 4.5: Color-coded output functions
function _gwt_success() {
    local message="$1"
    _gwt_show_progress "$message" "green"
}

function _gwt_warning() {
    local message="$1"
    _gwt_show_progress "$message" "yellow" >&2
}

function _gwt_error() {
    local message="$1"
    _gwt_show_progress "Error: $message" "red" >&2
}

# Task 4.6: Cleanup logic for failed operations
function _gwt_cleanup_failed_worktree() {
    local target_path="$1"
    local branch_name="$2"
    
    if [[ -z "$target_path" ]]; then
        return 1
    fi
    
    _gwt_warning "Cleaning up after failed worktree creation..."
    
    # Remove directory if it was created but is empty or incomplete
    if [[ -d "$target_path" ]]; then
        # Check if directory is empty or doesn't contain .git
        if [[ ! -f "$target_path/.git" ]] && [[ -z "$(ls -A "$target_path" 2>/dev/null)" ]]; then
            rmdir "$target_path" 2>/dev/null
            _gwt_warning "Removed empty directory: $target_path"
        fi
    fi
    
    # Attempt to remove the worktree from git's tracking if it exists
    if [[ -n "$branch_name" ]]; then
        git worktree remove "$target_path" --force 2>/dev/null || true
        _gwt_warning "Attempted to clean up git worktree references"
    fi
    
    return 0
}

# Task 4.7: Filesystem validation functions
function _gwt_validate_filesystem_access() {
    local target_path="$1"
    local container_dir
    local container_parent_dir
    
    if [[ -z "$target_path" ]]; then
        return 1
    fi
    
    container_dir=$(dirname "$target_path")
    container_parent_dir=$(dirname "$container_dir")
    
    # Check if container parent directory exists and is writable
    # We'll create the container directory if it doesn't exist
    if [[ ! -d "$container_parent_dir" ]]; then
        _gwt_error "Container parent directory '$container_parent_dir' does not exist"
        echo "Suggestion: Ensure you're in a valid git repository with accessible parent directory" >&2
        return 1
    fi
    
    if [[ ! -w "$container_parent_dir" ]]; then
        _gwt_error "No write permission for container parent directory '$container_parent_dir'"
        echo "Suggestion: Check directory permissions with 'ls -la \"$container_parent_dir\"' and adjust if needed" >&2
        return 1
    fi
    
    return 0
}

function _gwt_check_disk_space() {
    local target_path="$1"
    local min_space_mb=100  # Minimum 100MB required
    
    if [[ -z "$target_path" ]]; then
        return 1
    fi
    
    local container_dir
    local container_parent_dir
    container_dir=$(dirname "$target_path")
    container_parent_dir=$(dirname "$container_dir")
    
    # Get available disk space (cross-platform approach)
    local available_space
    if command -v df >/dev/null 2>&1; then
        # Use df to get available space in MB
        available_space=$(df -m "$container_parent_dir" 2>/dev/null | awk 'NR==2 {print $4}')
        
        if [[ -n "$available_space" && "$available_space" =~ ^[0-9]+$ ]]; then
            if [[ "$available_space" -lt "$min_space_mb" ]]; then
                _gwt_error "Insufficient disk space: ${available_space}MB available, ${min_space_mb}MB required"
                echo "Suggestion: Free up disk space or choose a different location with more available space" >&2
                return 1
            fi
        fi
    fi
    
    return 0
}

function _gwt_validate_path_length() {
    local target_path="$1"
    local max_path_length=255  # Conservative limit for most filesystems
    
    if [[ -z "$target_path" ]]; then
        return 1
    fi
    
    if [[ "${#target_path}" -gt "$max_path_length" ]]; then
        _gwt_error "Path too long: ${#target_path} characters (maximum: $max_path_length)"
        echo "Suggestion: Use a shorter directory name or create the worktree in a location with a shorter base path" >&2
        return 1
    fi
    
    return 0
}

# ============================================================================
# Zsh Tab Completion Integration (Task 5.3)
# ============================================================================

# Main completion function for gwt-create
function _gwt_create() {
    local context state line
    local -a arguments
    
    arguments=(
        '(-h --help)'{-h,--help}'[Show usage information]'
        '(--dry-run)--dry-run[Show what would be done without making changes]'
        '1:branch-name:_gwt_complete_branch_names'
        '2:target-directory:_files -/'
    )
    
    _arguments -s -S $arguments
}

# Complete branch names from local and remote branches
function _gwt_complete_branch_names() {
    local -a local_branches remote_branches all_branches
    local branch
    
    # Get local branches (excluding current branch and HEAD)
    while IFS= read -r branch; do
        # Skip current branch (marked with *) and HEAD
        if [[ ! "$branch" =~ ^\*\s && ! "$branch" =~ HEAD ]]; then
            # Clean up branch name (remove leading/trailing whitespace)
            branch=${branch##*[[:space:]]}
            branch=${branch%%[[:space:]]*}
            local_branches+=("$branch:local branch")
        fi
    done < <(git branch 2>/dev/null)
    
    # Get remote branches (excluding HEAD)
    while IFS= read -r branch; do
        if [[ ! "$branch" =~ HEAD && "$branch" =~ ^[[:space:]]*remotes/ ]]; then
            # Extract branch name from remotes/origin/branch-name format
            branch=${branch##*remotes/*/}
            branch=${branch##*[[:space:]]}
            branch=${branch%%[[:space:]]*}
            # Only include if not already in local branches
            local is_local=false
            local local_branch
            for local_branch in "${local_branches[@]%:*}"; do
                if [[ "$local_branch" == "$branch" ]]; then
                    is_local=true
                    break
                fi
            done
            if [[ "$is_local" == false ]]; then
                remote_branches+=("$branch:remote branch")
            fi
        fi
    done < <(git branch -r 2>/dev/null)
    
    # Combine local and remote branches
    all_branches=("${local_branches[@]}" "${remote_branches[@]}")
    
    # Use compadd to add completions with descriptions
    if (( ${#all_branches[@]} > 0 )); then
        local branch_info
        for branch_info in "${all_branches[@]}"; do
            local branch_name="${branch_info%:*}"
            local branch_desc="${branch_info#*:}"
            compadd -d "$branch_desc" "$branch_name"
        done
    else
        # Fallback: allow any input if no git branches found
        _message "branch name"
    fi
}

# Configuration File Parsing Functions
# These functions implement .gwt-config file discovery and parsing

# Find .gwt-config file in current directory or repository root
# Returns: Path to config file, or exits with code 1 if not found
function _gwt_find_config_file() {
    local config_file=".gwt-config"
    
    # Check current directory first
    if [[ -f "$config_file" ]]; then
        echo "$(pwd)/$config_file"
        return 0
    fi
    
    # Fall back to repository root
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ $? -eq 0 && -f "$repo_root/$config_file" ]]; then
        echo "$repo_root/$config_file"
        return 0
    fi
    
    # Config file not found
    return 1
}

# Parse .gwt-config file and output valid entries
# Usage: _gwt_parse_config_file <config-file-path>
function _gwt_parse_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file '$config_file' not found" >&2
        return 1
    fi
    
    local line
    while IFS= read -r line; do
        # Trim leading and trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        echo "$line"
    done < "$config_file"
}

# Expand glob patterns and handle exclusions from config entries
# Usage: _gwt_expand_config_patterns <config-file-path>
function _gwt_expand_config_patterns() {
    local config_file="$1"
    local -a entries=()
    local -a exclusions=()
    local line
    
    # First pass: collect all entries and exclusions
    while IFS= read -r line; do
        if [[ "$line" =~ ^! ]]; then
            # Exclusion pattern (remove ! prefix)
            exclusions+=("${line#!}")
        else
            # Regular entry
            entries+=("$line")
        fi
    done < <(_gwt_parse_config_file "$config_file")
    
    # Second pass: expand patterns and apply exclusions
    local entry
    for entry in "${entries[@]}"; do
        if [[ "$entry" =~ [\*\?\[\]] ]]; then
            # Expand glob pattern
            local -a expanded=()
            setopt NULL_GLOB
            expanded=(${~entry})
            unsetopt NULL_GLOB
            
            local expanded_item
            for expanded_item in "${expanded[@]}"; do
                if ! _gwt_is_excluded "$expanded_item" "${exclusions[@]}"; then
                    echo "$expanded_item"
                fi
            done
        else
            # Literal path
            if ! _gwt_is_excluded "$entry" "${exclusions[@]}"; then
                echo "$entry"
            fi
        fi
    done
}

# Check if an item matches any exclusion pattern
# Usage: _gwt_is_excluded <item> <exclusion-patterns...>
function _gwt_is_excluded() {
    local item="$1"
    shift
    local -a exclusions=("$@")
    
    local exclusion
    for exclusion in "${exclusions[@]}"; do
        if [[ "$exclusion" =~ [\*\?\[\]] ]]; then
            # Glob pattern exclusion
            if [[ "$item" == ${~exclusion} ]]; then
                return 0
            fi
        else
            # Literal exclusion
            if [[ "$item" == "$exclusion" ]]; then
                return 0
            fi
        fi
    done
    
    return 1
}

# Validate configuration entries and filter out non-existent files
# Usage: _gwt_validate_config_entries <config-file-path>
function _gwt_validate_config_entries() {
    local config_file="$1"
    local entry
    
    while IFS= read -r entry; do
        if [[ -e "$entry" ]]; then
            echo "$entry"
        fi
    done < <(_gwt_expand_config_patterns "$config_file")
}

# Get all valid configuration entries for copying
# Returns: List of files/directories to copy, or empty if no config
function _gwt_get_config_entries() {
    local config_file
    config_file=$(_gwt_find_config_file)
    
    if [[ $? -ne 0 ]]; then
        # No config file found - return empty (backward compatibility)
        return 0
    fi
    
    _gwt_validate_config_entries "$config_file"
}

# Alternative simpler completion function focusing on local branches only
function _gwt_complete_local_branches() {
    local -a branches
    local branch
    
    # Get local branches
    while IFS= read -r branch; do
        if [[ ! "$branch" =~ ^\*\s ]]; then
            branch=${branch##*[[:space:]]}
            branches+=("$branch")
        fi
    done < <(git branch 2>/dev/null)
    
    if (( ${#branches[@]} > 0 )); then
        compadd -a branches
    fi
}

# Register the completion function
if [[ -n "$ZSH_VERSION" ]] && command -v compdef >/dev/null 2>&1; then
    # Only register if we're in zsh and compdef is available
    compdef _gwt_create gwt-create
fi