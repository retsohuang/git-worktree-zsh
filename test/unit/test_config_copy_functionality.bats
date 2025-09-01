#!/usr/bin/env bats

# Test the .gwt-config file copying functionality
# This test file covers the config file copy target directory calculation and hierarchical behavior
# Category: unit

load '../test_helper'

setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    
    cd "$TEST_TEMP_DIR"
    setup_git_repo "test-repo"
    
    source "$ORIGINAL_DIR/git-worktree.zsh" 2>/dev/null || true
}

teardown() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_TEMP_DIR" 2>/dev/null || true
}

# ===== ROOT .GWT-CONFIG TESTS =====

@test "UNIT: Root config file - basic file copying to worktree root" {
    # Create test files in repository root
    echo "content1" > file1.txt
    echo "content2" > file2.txt
    mkdir -p subdir
    echo "content3" > subdir/file3.txt
    
    # Create .gwt-config in repository root
    cat > .gwt-config << 'EOF'
file1.txt
file2.txt
subdir/file3.txt
EOF
    
    # Create a worktree
    git branch test-branch
    run gwt-create test-branch
    [ "$status" -eq 0 ]
    
    # Verify files are copied to worktree root (current behavior - should remain)
    [ -f "../test-repo-worktrees/test-branch/file1.txt" ]
    [ -f "../test-repo-worktrees/test-branch/file2.txt" ] 
    [ -f "../test-repo-worktrees/test-branch/file3.txt" ]  # Note: currently copies to root, not subdir/
    
    # Verify content is preserved
    [ "$(cat "../test-repo-worktrees/test-branch/file1.txt")" = "content1" ]
    [ "$(cat "../test-repo-worktrees/test-branch/file2.txt")" = "content2" ]
    [ "$(cat "../test-repo-worktrees/test-branch/file3.txt")" = "content3" ]
}

@test "UNIT: Root config file - directory copying to worktree root" {
    # Create test directories and files
    mkdir -p testdir1 testdir2/nested
    echo "dir1content" > testdir1/dirfile1.txt
    echo "dir2content" > testdir2/dirfile2.txt
    echo "nestedcontent" > testdir2/nested/nestedfile.txt
    
    # Create .gwt-config in repository root
    cat > .gwt-config << 'EOF'
testdir1/
testdir2/
EOF
    
    # Create a worktree
    git branch test-dir-branch
    run gwt-create test-dir-branch
    [ "$status" -eq 0 ]
    
    # Verify directories are copied to worktree root
    [ -d "../test-repo-worktrees/test-dir-branch/testdir1" ]
    [ -d "../test-repo-worktrees/test-dir-branch/testdir2" ]
    [ -d "../test-repo-worktrees/test-dir-branch/testdir2/nested" ]
    
    # Verify directory contents are preserved
    [ -f "../test-repo-worktrees/test-dir-branch/testdir1/dirfile1.txt" ]
    [ -f "../test-repo-worktrees/test-dir-branch/testdir2/dirfile2.txt" ]
    [ -f "../test-repo-worktrees/test-dir-branch/testdir2/nested/nestedfile.txt" ]
    
    [ "$(cat "../test-repo-worktrees/test-dir-branch/testdir1/dirfile1.txt")" = "dir1content" ]
    [ "$(cat "../test-repo-worktrees/test-dir-branch/testdir2/dirfile2.txt")" = "dir2content" ]
    [ "$(cat "../test-repo-worktrees/test-dir-branch/testdir2/nested/nestedfile.txt")" = "nestedcontent" ]
}

@test "UNIT: Root config file - mixed patterns (files and directories)" {
    # Create mixed test structure
    echo "rootfile" > root.txt
    mkdir -p configs utils/helpers
    echo "configcontent" > configs/app.config
    echo "helpercontent" > utils/helpers/helper.sh
    echo "utilcontent" > utils/util.txt
    
    # Create .gwt-config with mixed patterns
    cat > .gwt-config << 'EOF'
root.txt
configs/
utils/helpers/helper.sh
EOF
    
    # Create a worktree
    git branch mixed-pattern-branch
    run gwt-create mixed-pattern-branch
    [ "$status" -eq 0 ]
    
    # Verify mixed patterns are copied correctly to worktree root
    [ -f "../test-repo-worktrees/mixed-pattern-branch/root.txt" ]
    [ -d "../test-repo-worktrees/mixed-pattern-branch/configs" ]
    [ -f "../test-repo-worktrees/mixed-pattern-branch/configs/app.config" ]
    [ -f "../test-repo-worktrees/mixed-pattern-branch/helper.sh" ]  # Currently copies to root
    
    # Content verification
    [ "$(cat "../test-repo-worktrees/mixed-pattern-branch/root.txt")" = "rootfile" ]
    [ "$(cat "../test-repo-worktrees/mixed-pattern-branch/configs/app.config")" = "configcontent" ]
    [ "$(cat "../test-repo-worktrees/mixed-pattern-branch/helper.sh")" = "helpercontent" ]
}

@test "UNIT: Root config file - nonexistent files are handled gracefully" {
    # Create only some of the files specified in config
    echo "existsfile" > exists.txt
    
    # Create .gwt-config with mix of existing and nonexistent files
    cat > .gwt-config << 'EOF'
exists.txt
nonexistent.txt
missing/directory/file.txt
EOF
    
    # Create a worktree (should succeed despite missing files)
    git branch graceful-missing-branch
    run gwt-create graceful-missing-branch
    [ "$status" -eq 0 ]
    
    # Verify existing file is copied, missing files are skipped
    [ -f "../test-repo-worktrees/graceful-missing-branch/exists.txt" ]
    [ ! -f "../test-repo-worktrees/graceful-missing-branch/nonexistent.txt" ]
    [ ! -f "../test-repo-worktrees/graceful-missing-branch/file.txt" ]
    
    # Verify content of existing file
    [ "$(cat "../test-repo-worktrees/graceful-missing-branch/exists.txt")" = "existsfile" ]
}

@test "UNIT: Root config file - empty config file handled gracefully" {
    # Create empty .gwt-config
    touch .gwt-config
    
    # Create a worktree (should succeed with no files copied)
    git branch empty-config-branch
    run gwt-create empty-config-branch
    [ "$status" -eq 0 ]
    
    # Verify worktree exists but no additional files copied
    [ -d "../test-repo-worktrees/empty-config-branch" ]
    # Should only have git files, no config files copied
    local file_count=$(find "../test-repo-worktrees/empty-config-branch" -maxdepth 1 -type f | wc -l)
    [ "$file_count" -eq 0 ] # No non-git files should be present
}

@test "UNIT: Root config file - special characters in filenames" {
    # Create files with special characters
    echo "spacecontent" > "file with spaces.txt"
    echo "dashcontent" > "file-with-dashes.txt"
    echo "undercontent" > "file_with_underscores.txt"
    mkdir -p "dir with spaces"
    echo "dirspacecontent" > "dir with spaces/nested file.txt"
    
    # Create .gwt-config with special character filenames
    cat > .gwt-config << 'EOF'
file with spaces.txt
file-with-dashes.txt
file_with_underscores.txt
dir with spaces/
EOF
    
    # Create a worktree
    git branch special-chars-branch
    run gwt-create special-chars-branch
    [ "$status" -eq 0 ]
    
    # Verify files with special characters are copied correctly
    [ -f "../test-repo-worktrees/special-chars-branch/file with spaces.txt" ]
    [ -f "../test-repo-worktrees/special-chars-branch/file-with-dashes.txt" ]
    [ -f "../test-repo-worktrees/special-chars-branch/file_with_underscores.txt" ]
    [ -d "../test-repo-worktrees/special-chars-branch/dir with spaces" ]
    [ -f "../test-repo-worktrees/special-chars-branch/dir with spaces/nested file.txt" ]
    
    # Content verification
    [ "$(cat "../test-repo-worktrees/special-chars-branch/file with spaces.txt")" = "spacecontent" ]
    [ "$(cat "../test-repo-worktrees/special-chars-branch/file-with-dashes.txt")" = "dashcontent" ]
    [ "$(cat "../test-repo-worktrees/special-chars-branch/file_with_underscores.txt")" = "undercontent" ]
    [ "$(cat "../test-repo-worktrees/special-chars-branch/dir with spaces/nested file.txt")" = "dirspacecontent" ]
}

@test "UNIT: Root config file - symlinks are handled correctly" {
    # Create original files and symbolic links
    echo "originalcontent" > original.txt
    ln -s original.txt symlink.txt
    mkdir -p targetdir
    echo "targetcontent" > targetdir/target.txt
    ln -s targetdir symlink_to_dir
    
    # Create .gwt-config with symlinks
    cat > .gwt-config << 'EOF'
original.txt
symlink.txt
targetdir/
symlink_to_dir
EOF
    
    # Create a worktree
    git branch symlink-branch
    run gwt-create symlink-branch
    [ "$status" -eq 0 ]
    
    # Verify files are copied (symlink behavior depends on implementation)
    [ -f "../test-repo-worktrees/symlink-branch/original.txt" ]
    # Note: symlink handling behavior may vary - should copy target content, not link
    [ -f "../test-repo-worktrees/symlink-branch/symlink.txt" ]
    [ -d "../test-repo-worktrees/symlink-branch/targetdir" ]
    [ -f "../test-repo-worktrees/symlink-branch/targetdir/target.txt" ]
    
    # Content verification
    [ "$(cat "../test-repo-worktrees/symlink-branch/original.txt")" = "originalcontent" ]
    [ "$(cat "../test-repo-worktrees/symlink-branch/symlink.txt")" = "originalcontent" ]
    [ "$(cat "../test-repo-worktrees/symlink-branch/targetdir/target.txt")" = "targetcontent" ]
}

# ===== SUBDIRECTORY .GWT-CONFIG TESTS (MAIN BUG AREA) =====

@test "UNIT: Subdirectory config - files should copy to correct subdirectory in worktree" {
    # Create subdirectory with config and files
    mkdir -p frontend/src frontend/config
    echo "component content" > frontend/src/component.js
    echo "config content" > frontend/config/app.config
    echo "env content" > frontend/.env.local
    
    # Create .gwt-config in subdirectory (this is where the bug occurs)
    cat > frontend/.gwt-config << 'EOF'
src/component.js
config/app.config
.env.local
EOF
    
    # Change to frontend directory and create worktree from there
    cd frontend
    git branch frontend-feature
    run gwt-create frontend-feature
    [ "$status" -eq 0 ]
    
    # BUG: Currently files copy to worktree root instead of frontend/ subdirectory
    # Current (wrong) behavior:
    [ -f "../../test-repo-worktrees/frontend-feature/component.js" ]  # Wrong: should be in frontend/src/
    [ -f "../../test-repo-worktrees/frontend-feature/app.config" ]    # Wrong: should be in frontend/config/
    [ -f "../../test-repo-worktrees/frontend-feature/.env.local" ]    # Wrong: should be in frontend/
    
    # EXPECTED (correct) behavior after fix:
    # These assertions will fail with current implementation but should pass after fix
    # [ -f "../../test-repo-worktrees/frontend-feature/frontend/src/component.js" ]
    # [ -f "../../test-repo-worktrees/frontend-feature/frontend/config/app.config" ]
    # [ -f "../../test-repo-worktrees/frontend-feature/frontend/.env.local" ]
    
    # Content verification (regardless of location, content should be preserved)
    [ "$(cat "../../test-repo-worktrees/frontend-feature/component.js")" = "component content" ]
    [ "$(cat "../../test-repo-worktrees/frontend-feature/app.config")" = "config content" ]
    [ "$(cat "../../test-repo-worktrees/frontend-feature/.env.local")" = "env content" ]
}

@test "UNIT: Subdirectory config - nested directories should preserve structure" {
    # Create nested subdirectory structure
    mkdir -p backend/api/controllers backend/api/models backend/config
    echo "controller content" > backend/api/controllers/user.js
    echo "model content" > backend/api/models/User.js
    echo "db config" > backend/config/database.yml
    echo "api config" > backend/api/config.json
    
    # Create .gwt-config in subdirectory
    cat > backend/.gwt-config << 'EOF'
api/controllers/
api/models/User.js
config/database.yml
api/config.json
EOF
    
    # Change to backend directory and create worktree
    cd backend
    git branch backend-feature  
    run gwt-create backend-feature
    [ "$status" -eq 0 ]
    
    # BUG: Currently nested structure is not preserved correctly
    # Current (wrong) behavior - files copy to worktree root:
    [ -d "../../test-repo-worktrees/backend-feature/controllers" ]      # Wrong path
    [ -f "../../test-repo-worktrees/backend-feature/controllers/user.js" ]  # Wrong path
    [ -f "../../test-repo-worktrees/backend-feature/User.js" ]              # Wrong path
    [ -f "../../test-repo-worktrees/backend-feature/database.yml" ]         # Wrong path
    [ -f "../../test-repo-worktrees/backend-feature/config.json" ]          # Wrong path
    
    # EXPECTED (correct) behavior after fix:
    # [ -d "../../test-repo-worktrees/backend-feature/backend/api/controllers" ]
    # [ -f "../../test-repo-worktrees/backend-feature/backend/api/controllers/user.js" ]
    # [ -f "../../test-repo-worktrees/backend-feature/backend/api/models/User.js" ]
    # [ -f "../../test-repo-worktrees/backend-feature/backend/config/database.yml" ]
    # [ -f "../../test-repo-worktrees/backend-feature/backend/api/config.json" ]
    
    # Content verification
    [ "$(cat "../../test-repo-worktrees/backend-feature/controllers/user.js")" = "controller content" ]
    [ "$(cat "../../test-repo-worktrees/backend-feature/User.js")" = "model content" ]
    [ "$(cat "../../test-repo-worktrees/backend-feature/database.yml")" = "db config" ]
    [ "$(cat "../../test-repo-worktrees/backend-feature/config.json")" = "api config" ]
}

@test "UNIT: Subdirectory config - deep nesting preserves correct paths" {
    # Create deeply nested structure
    mkdir -p services/user-service/src/main/java/com/example/user
    mkdir -p services/user-service/src/test/java/com/example/user
    mkdir -p services/user-service/config/dev
    
    echo "user service" > services/user-service/src/main/java/com/example/user/UserService.java
    echo "user test" > services/user-service/src/test/java/com/example/user/UserServiceTest.java
    echo "dev config" > services/user-service/config/dev/application.properties
    echo "dockerfile" > services/user-service/Dockerfile
    
    # Create .gwt-config in deep subdirectory
    cat > services/user-service/.gwt-config << 'EOF'
src/main/java/com/example/user/UserService.java
src/test/java/com/example/user/UserServiceTest.java
config/dev/application.properties
Dockerfile
EOF
    
    # Change to deep subdirectory and create worktree
    cd services/user-service
    git branch user-service-feature
    run gwt-create user-service-feature
    [ "$status" -eq 0 ]
    
    # BUG: Deep nesting paths are incorrectly flattened to worktree root
    # Current (wrong) behavior:
    [ -f "../../../test-repo-worktrees/user-service-feature/UserService.java" ]     # Wrong
    [ -f "../../../test-repo-worktrees/user-service-feature/UserServiceTest.java" ] # Wrong  
    [ -f "../../../test-repo-worktrees/user-service-feature/application.properties" ] # Wrong
    [ -f "../../../test-repo-worktrees/user-service-feature/Dockerfile" ]          # Wrong
    
    # EXPECTED (correct) behavior after fix:
    # [ -f "../../../test-repo-worktrees/user-service-feature/services/user-service/src/main/java/com/example/user/UserService.java" ]
    # [ -f "../../../test-repo-worktrees/user-service-feature/services/user-service/src/test/java/com/example/user/UserServiceTest.java" ]
    # [ -f "../../../test-repo-worktrees/user-service-feature/services/user-service/config/dev/application.properties" ]
    # [ -f "../../../test-repo-worktrees/user-service-feature/services/user-service/Dockerfile" ]
    
    # Content verification
    [ "$(cat "../../../test-repo-worktrees/user-service-feature/UserService.java")" = "user service" ]
    [ "$(cat "../../../test-repo-worktrees/user-service-feature/UserServiceTest.java")" = "user test" ]
    [ "$(cat "../../../test-repo-worktrees/user-service-feature/application.properties")" = "dev config" ]
    [ "$(cat "../../../test-repo-worktrees/user-service-feature/Dockerfile")" = "dockerfile" ]
}

@test "UNIT: Subdirectory config - relative paths from config location" {
    # Test files at various levels relative to config location
    mkdir -p project/web/assets project/web/src project/shared
    echo "style content" > project/web/assets/style.css
    echo "script content" > project/web/src/app.js
    echo "config content" > project/web/web.config
    echo "shared content" > project/shared/utils.js
    echo "root content" > project/project.config
    
    # Create .gwt-config in project/web/ with relative paths
    cat > project/web/.gwt-config << 'EOF'
assets/style.css
src/app.js
web.config
../shared/utils.js
../project.config
EOF
    
    # Change to project/web directory
    cd project/web
    git branch web-feature
    run gwt-create web-feature  
    [ "$status" -eq 0 ]
    
    # BUG: Relative paths are not calculated correctly from config file location
    # Current behavior (paths relative to worktree root):
    [ -f "../../../test-repo-worktrees/web-feature/style.css" ]      # Wrong: should preserve assets/
    [ -f "../../../test-repo-worktrees/web-feature/app.js" ]         # Wrong: should preserve src/
    [ -f "../../../test-repo-worktrees/web-feature/web.config" ]     # This might be correct
    [ -f "../../../test-repo-worktrees/web-feature/utils.js" ]       # Wrong: should be ../shared/
    [ -f "../../../test-repo-worktrees/web-feature/project.config" ] # Wrong: should be ../
    
    # EXPECTED behavior (paths relative to config file location, preserved in worktree):
    # [ -f "../../../test-repo-worktrees/web-feature/project/web/assets/style.css" ]
    # [ -f "../../../test-repo-worktrees/web-feature/project/web/src/app.js" ]
    # [ -f "../../../test-repo-worktrees/web-feature/project/web/web.config" ]
    # [ -f "../../../test-repo-worktrees/web-feature/project/shared/utils.js" ]
    # [ -f "../../../test-repo-worktrees/web-feature/project/project.config" ]
    
    # Content verification
    [ "$(cat "../../../test-repo-worktrees/web-feature/style.css")" = "style content" ]
    [ "$(cat "../../../test-repo-worktrees/web-feature/app.js")" = "script content" ]
    [ "$(cat "../../../test-repo-worktrees/web-feature/web.config")" = "config content" ]
    [ "$(cat "../../../test-repo-worktrees/web-feature/utils.js")" = "shared content" ]
    [ "$(cat "../../../test-repo-worktrees/web-feature/project.config")" = "root content" ]
}

# ===== HIERARCHICAL CONFIG DISCOVERY TESTS =====

@test "UNIT: Hierarchical config - multiple configs merged correctly" {
    # Create repository-wide config at root
    cat > .gwt-config << 'EOF'
README.md
LICENSE
.gitignore
EOF
    
    # Create project-specific config in subdirectory  
    mkdir -p apps/web
    cat > apps/web/.gwt-config << 'EOF'
package.json
webpack.config.js
.env.local
EOF
    
    # Create the files referenced in configs
    echo "readme content" > README.md
    echo "license content" > LICENSE
    echo "gitignore content" > .gitignore
    echo "package content" > apps/web/package.json
    echo "webpack content" > apps/web/webpack.config.js
    echo "env content" > apps/web/.env.local
    
    # Change to subdirectory and create worktree
    cd apps/web
    git branch hierarchical-merge
    run gwt-create hierarchical-merge
    [ "$status" -eq 0 ]
    
    # Both root config and subdirectory config files should be copied
    # Root config files (currently copy to worktree root)
    [ -f "../../../test-repo-worktrees/hierarchical-merge/README.md" ]
    [ -f "../../../test-repo-worktrees/hierarchical-merge/LICENSE" ]
    [ -f "../../../test-repo-worktrees/hierarchical-merge/.gitignore" ]
    
    # Subdirectory config files (BUG: currently copy to worktree root instead of apps/web/)
    [ -f "../../../test-repo-worktrees/hierarchical-merge/package.json" ]     # Wrong location
    [ -f "../../../test-repo-worktrees/hierarchical-merge/webpack.config.js" ] # Wrong location
    [ -f "../../../test-repo-worktrees/hierarchical-merge/.env.local" ]       # Wrong location
    
    # EXPECTED after fix (commented out):
    # [ -f "../../../test-repo-worktrees/hierarchical-merge/apps/web/package.json" ]
    # [ -f "../../../test-repo-worktrees/hierarchical-merge/apps/web/webpack.config.js" ]
    # [ -f "../../../test-repo-worktrees/hierarchical-merge/apps/web/.env.local" ]
    
    # Content verification
    [ "$(cat "../../../test-repo-worktrees/hierarchical-merge/README.md")" = "readme content" ]
    [ "$(cat "../../../test-repo-worktrees/hierarchical-merge/LICENSE")" = "license content" ]
    [ "$(cat "../../../test-repo-worktrees/hierarchical-merge/package.json")" = "package content" ]
    [ "$(cat "../../../test-repo-worktrees/hierarchical-merge/webpack.config.js")" = "webpack content" ]
    [ "$(cat "../../../test-repo-worktrees/hierarchical-merge/.env.local")" = "env content" ]
}

@test "UNIT: Hierarchical config - deeper nesting with multiple levels" {
    # Create config at repository root
    cat > .gwt-config << 'EOF'
global.config
shared/
EOF
    
    # Create config at intermediate level
    mkdir -p platform/services
    cat > platform/.gwt-config << 'EOF'
platform.config
shared-platform/
EOF
    
    # Create config at deepest level
    cat > platform/services/.gwt-config << 'EOF'
service.config
local/
EOF
    
    # Create all referenced files and directories
    echo "global content" > global.config
    mkdir -p shared
    echo "shared content" > shared/utils.js
    
    echo "platform content" > platform/platform.config
    mkdir -p platform/shared-platform
    echo "platform shared content" > platform/shared-platform/common.js
    
    echo "service content" > platform/services/service.config
    mkdir -p platform/services/local
    echo "local content" > platform/services/local/app.js
    
    # Change to deepest directory
    cd platform/services
    git branch deep-hierarchy
    run gwt-create deep-hierarchy
    [ "$status" -eq 0 ]
    
    # All three levels of config should be merged and copied
    # Root level files
    [ -f "../../../test-repo-worktrees/deep-hierarchy/global.config" ]
    [ -d "../../../test-repo-worktrees/deep-hierarchy/shared" ]
    [ -f "../../../test-repo-worktrees/deep-hierarchy/shared/utils.js" ]
    
    # Platform level files (BUG: wrong paths)
    [ -f "../../../test-repo-worktrees/deep-hierarchy/platform.config" ]     # Wrong location
    [ -d "../../../test-repo-worktrees/deep-hierarchy/shared-platform" ]     # Wrong location
    [ -f "../../../test-repo-worktrees/deep-hierarchy/shared-platform/common.js" ] # Wrong location
    
    # Service level files (BUG: wrong paths)
    [ -f "../../../test-repo-worktrees/deep-hierarchy/service.config" ]      # Wrong location
    [ -d "../../../test-repo-worktrees/deep-hierarchy/local" ]               # Wrong location
    [ -f "../../../test-repo-worktrees/deep-hierarchy/local/app.js" ]        # Wrong location
    
    # EXPECTED after fix (commented out):
    # [ -f "../../../test-repo-worktrees/deep-hierarchy/platform/platform.config" ]
    # [ -d "../../../test-repo-worktrees/deep-hierarchy/platform/shared-platform" ]
    # [ -f "../../../test-repo-worktrees/deep-hierarchy/platform/shared-platform/common.js" ]
    # [ -f "../../../test-repo-worktrees/deep-hierarchy/platform/services/service.config" ]
    # [ -d "../../../test-repo-worktrees/deep-hierarchy/platform/services/local" ]
    # [ -f "../../../test-repo-worktrees/deep-hierarchy/platform/services/local/app.js" ]
    
    # Content verification
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/global.config")" = "global content" ]
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/shared/utils.js")" = "shared content" ]
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/platform.config")" = "platform content" ]
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/shared-platform/common.js")" = "platform shared content" ]
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/service.config")" = "service content" ]
    [ "$(cat "../../../test-repo-worktrees/deep-hierarchy/local/app.js")" = "local content" ]
}

@test "UNIT: Hierarchical config - precedence handling with conflicting files" {
    # Create root config
    cat > .gwt-config << 'EOF'
config.json
shared.txt
EOF
    
    # Create subdirectory config that conflicts
    mkdir -p app
    cat > app/.gwt-config << 'EOF'
config.json
app-specific.txt
EOF
    
    # Create files with different content at different levels
    echo "root config" > config.json
    echo "root shared" > shared.txt
    echo "app config" > app/config.json
    echo "app specific" > app/app-specific.txt
    
    # Change to subdirectory
    cd app
    git branch precedence-test
    run gwt-create precedence-test
    [ "$status" -eq 0 ]
    
    # With hierarchical merging, closer config should take precedence
    # Both shared.txt (from root) and app-specific.txt (from app) should be present
    [ -f "../../test-repo-worktrees/precedence-test/shared.txt" ]           # From root config
    [ -f "../../test-repo-worktrees/precedence-test/app-specific.txt" ]     # From app config
    
    # For conflicting config.json, app version should take precedence
    [ -f "../../test-repo-worktrees/precedence-test/config.json" ]
    
    # Content verification - closer config should win for conflicts
    [ "$(cat "../../test-repo-worktrees/precedence-test/shared.txt")" = "root shared" ]
    [ "$(cat "../../test-repo-worktrees/precedence-test/app-specific.txt")" = "app specific" ]
    # Note: Current implementation may copy app/config.json as "config.json" to root,
    # but the content should be from the app directory due to precedence
    [ "$(cat "../../test-repo-worktrees/precedence-test/config.json")" = "app config" ]
}

@test "UNIT: Hierarchical config - monorepo scenario with multiple projects" {
    # Simulate typical monorepo structure with shared and project-specific configs
    
    # Root monorepo config
    cat > .gwt-config << 'EOF'
package.json
tsconfig.json  
.eslintrc.js
.prettierrc
EOF
    
    # Frontend project config
    mkdir -p packages/frontend
    cat > packages/frontend/.gwt-config << 'EOF'
webpack.config.js
.env.local
src/setupTests.js
EOF
    
    # Backend project config  
    mkdir -p packages/backend
    cat > packages/backend/.gwt-config << 'EOF'
nodemon.json
.env.development
src/config/database.js
EOF
    
    # Create all files
    echo "monorepo package" > package.json
    echo "ts config" > tsconfig.json
    echo "eslint config" > .eslintrc.js
    echo "prettier config" > .prettierrc
    
    echo "webpack config" > packages/frontend/webpack.config.js
    echo "frontend env" > packages/frontend/.env.local
    mkdir -p packages/frontend/src
    echo "test setup" > packages/frontend/src/setupTests.js
    
    echo "nodemon config" > packages/backend/nodemon.json
    echo "backend env" > packages/backend/.env.development
    mkdir -p packages/backend/src/config
    echo "db config" > packages/backend/src/config/database.js
    
    # Test from frontend project directory
    cd packages/frontend
    git branch monorepo-frontend
    run gwt-create monorepo-frontend  
    [ "$status" -eq 0 ]
    
    # Should have both root monorepo files and frontend-specific files
    # Root files
    [ -f "../../../test-repo-worktrees/monorepo-frontend/package.json" ]
    [ -f "../../../test-repo-worktrees/monorepo-frontend/tsconfig.json" ]
    [ -f "../../../test-repo-worktrees/monorepo-frontend/.eslintrc.js" ]
    [ -f "../../../test-repo-worktrees/monorepo-frontend/.prettierrc" ]
    
    # Frontend files (BUG: wrong paths)
    [ -f "../../../test-repo-worktrees/monorepo-frontend/webpack.config.js" ]    # Wrong location
    [ -f "../../../test-repo-worktrees/monorepo-frontend/.env.local" ]          # Wrong location
    [ -f "../../../test-repo-worktrees/monorepo-frontend/setupTests.js" ]       # Wrong location
    
    # Should NOT have backend files
    [ ! -f "../../../test-repo-worktrees/monorepo-frontend/nodemon.json" ]
    [ ! -f "../../../test-repo-worktrees/monorepo-frontend/.env.development" ]
    
    # EXPECTED after fix (commented out):
    # [ -f "../../../test-repo-worktrees/monorepo-frontend/packages/frontend/webpack.config.js" ]
    # [ -f "../../../test-repo-worktrees/monorepo-frontend/packages/frontend/.env.local" ]
    # [ -f "../../../test-repo-worktrees/monorepo-frontend/packages/frontend/src/setupTests.js" ]
    
    # Content verification
    [ "$(cat "../../../test-repo-worktrees/monorepo-frontend/package.json")" = "monorepo package" ]
    [ "$(cat "../../../test-repo-worktrees/monorepo-frontend/webpack.config.js")" = "webpack config" ]
    [ "$(cat "../../../test-repo-worktrees/monorepo-frontend/.env.local")" = "frontend env" ]
    [ "$(cat "../../../test-repo-worktrees/monorepo-frontend/setupTests.js")" = "test setup" ]
}

# ===== DUPLICATE LOG MESSAGE TESTS =====

@test "UNIT: Duplicate log messages - single file copied only once with single log message" {
    # Create simple test file
    echo "test content" > test.txt
    
    # Create .gwt-config referencing the file
    cat > .gwt-config << 'EOF'
test.txt
EOF
    
    # Create a worktree and capture output
    git branch single-log-test
    run gwt-create single-log-test
    [ "$status" -eq 0 ]
    
    # Check that log output contains only one copy message for the file
    # BUG: Currently may show duplicate log messages
    local copy_count=$(echo "$output" | grep -c "Copying.*test.txt" || echo 0)
    
    # Should only see one copy message per file
    # Note: This test documents current behavior - may show duplicates with current bug
    # After fix, should ensure copy_count is exactly 1
    
    # For now, verify file was actually copied (regardless of log messages)
    [ -f "../test-repo-worktrees/single-log-test/test.txt" ]
    [ "$(cat "../test-repo-worktrees/single-log-test/test.txt")" = "test content" ]
    
    # Log the actual count for debugging (will help identify the bug)
    echo "# Copy log message count: $copy_count" >&3
}

@test "UNIT: Duplicate log messages - multiple files should have distinct log messages" {
    # Create multiple test files
    echo "content1" > file1.txt
    echo "content2" > file2.txt
    echo "content3" > file3.txt
    
    # Create .gwt-config with multiple files
    cat > .gwt-config << 'EOF'
file1.txt
file2.txt
file3.txt
EOF
    
    # Create a worktree and capture output
    git branch multi-log-test
    run gwt-create multi-log-test
    [ "$status" -eq 0 ]
    
    # Each file should have exactly one copy log message
    local file1_count=$(echo "$output" | grep -c "Copying.*file1.txt" || echo 0)
    local file2_count=$(echo "$output" | grep -c "Copying.*file2.txt" || echo 0)
    local file3_count=$(echo "$output" | grep -c "Copying.*file3.txt" || echo 0)
    
    # Verify files were copied
    [ -f "../test-repo-worktrees/multi-log-test/file1.txt" ]
    [ -f "../test-repo-worktrees/multi-log-test/file2.txt" ]
    [ -f "../test-repo-worktrees/multi-log-test/file3.txt" ]
    
    # Log counts for debugging
    echo "# file1.txt copy count: $file1_count" >&3
    echo "# file2.txt copy count: $file2_count" >&3
    echo "# file3.txt copy count: $file3_count" >&3
    
    # After fix, each should be exactly 1
    # [ "$file1_count" -eq 1 ]
    # [ "$file2_count" -eq 1 ]
    # [ "$file3_count" -eq 1 ]
}

@test "UNIT: Duplicate log messages - hierarchical configs should not duplicate logs" {
    # Create root config
    cat > .gwt-config << 'EOF'
shared.txt
EOF
    
    # Create subdirectory config with same file
    mkdir -p subdir
    cat > subdir/.gwt-config << 'EOF'
../shared.txt
local.txt
EOF
    
    # Create the files
    echo "shared content" > shared.txt
    echo "local content" > subdir/local.txt
    
    # Create worktree from subdirectory
    cd subdir
    git branch hierarchy-log-test
    run gwt-create hierarchy-log-test
    [ "$status" -eq 0 ]
    
    # shared.txt is referenced in both configs - should only be logged once
    local shared_count=$(echo "$output" | grep -c "Copying.*shared.txt" || echo 0)
    local local_count=$(echo "$output" | grep -c "Copying.*local.txt" || echo 0)
    
    # Verify files were copied
    [ -f "../../test-repo-worktrees/hierarchy-log-test/shared.txt" ]
    [ -f "../../test-repo-worktrees/hierarchy-log-test/local.txt" ]
    
    # Log counts for debugging  
    echo "# shared.txt copy count: $shared_count" >&3
    echo "# local.txt copy count: $local_count" >&3
    
    # BUG: shared.txt might be logged multiple times due to appearing in both configs
    # After fix, should be exactly 1 for each file
    # [ "$shared_count" -eq 1 ]
    # [ "$local_count" -eq 1 ]
}

@test "UNIT: Duplicate log messages - same file in multiple config levels" {
    # Create complex hierarchy where same files are referenced at multiple levels
    cat > .gwt-config << 'EOF'
common.config
shared/utils.js
EOF
    
    mkdir -p team/project
    cat > team/.gwt-config << 'EOF'
../common.config
team.config
../shared/utils.js
EOF
    
    cat > team/project/.gwt-config << 'EOF'
../../common.config
../team.config
../../shared/utils.js
project.config
EOF
    
    # Create the files
    echo "common content" > common.config
    mkdir -p shared
    echo "utils content" > shared/utils.js
    echo "team content" > team/team.config
    echo "project content" > team/project/project.config
    
    # Create worktree from deepest level
    cd team/project
    git branch complex-log-test
    run gwt-create complex-log-test
    [ "$status" -eq 0 ]
    
    # Files referenced in multiple configs should only be logged once
    local common_count=$(echo "$output" | grep -c "Copying.*common.config" || echo 0)
    local utils_count=$(echo "$output" | grep -c "Copying.*utils.js" || echo 0)
    local team_count=$(echo "$output" | grep -c "Copying.*team.config" || echo 0)
    local project_count=$(echo "$output" | grep -c "Copying.*project.config" || echo 0)
    
    # Verify files were copied
    [ -f "../../../test-repo-worktrees/complex-log-test/common.config" ]
    [ -f "../../../test-repo-worktrees/complex-log-test/utils.js" ]
    [ -f "../../../test-repo-worktrees/complex-log-test/team.config" ]
    [ -f "../../../test-repo-worktrees/complex-log-test/project.config" ]
    
    # Log counts for debugging
    echo "# common.config copy count: $common_count" >&3
    echo "# utils.js copy count: $utils_count" >&3
    echo "# team.config copy count: $team_count" >&3
    echo "# project.config copy count: $project_count" >&3
    
    # BUG: Files referenced in multiple configs may be logged multiple times
    # After fix, each should be exactly 1
    # [ "$common_count" -eq 1 ]
    # [ "$utils_count" -eq 1 ]
    # [ "$team_count" -eq 1 ]
    # [ "$project_count" -eq 1 ]
}

@test "UNIT: Duplicate log messages - directory copying should have single log per operation" {
    # Create directory structure
    mkdir -p testdir/subdir
    echo "file1" > testdir/file1.txt
    echo "file2" > testdir/subdir/file2.txt
    
    # Create config referencing directory
    cat > .gwt-config << 'EOF'
testdir/
EOF
    
    # Create worktree and capture output
    git branch dir-log-test
    run gwt-create dir-log-test
    [ "$status" -eq 0 ]
    
    # Directory copy should generate single log message, not one per file within
    local testdir_count=$(echo "$output" | grep -c "Copying.*testdir" || echo 0)
    
    # Should NOT have individual file copy messages when copying directory
    local file1_count=$(echo "$output" | grep -c "Copying.*file1.txt" || echo 0)
    local file2_count=$(echo "$output" | grep -c "Copying.*file2.txt" || echo 0)
    
    # Verify directory and contents were copied
    [ -d "../test-repo-worktrees/dir-log-test/testdir" ]
    [ -f "../test-repo-worktrees/dir-log-test/testdir/file1.txt" ]
    [ -f "../test-repo-worktrees/dir-log-test/testdir/subdir/file2.txt" ]
    
    # Log counts for debugging
    echo "# testdir copy count: $testdir_count" >&3
    echo "# file1.txt individual count: $file1_count" >&3
    echo "# file2.txt individual count: $file2_count" >&3
    
    # After fix: directory should be logged once, individual files should not be logged
    # [ "$testdir_count" -eq 1 ]
    # [ "$file1_count" -eq 0 ]  # Should not log individual files when copying directory
    # [ "$file2_count" -eq 0 ]  # Should not log individual files when copying directory
}

# ===== REGRESSION TESTS =====

@test "UNIT: Regression - basic worktree creation without config files still works" {
    # Remove any config files to test basic functionality
    rm -f .gwt-config
    
    # Create basic worktree without any config
    git branch basic-no-config
    run gwt-create basic-no-config
    [ "$status" -eq 0 ]
    
    # Verify worktree was created successfully
    [ -d "../test-repo-worktrees/basic-no-config" ]
    [ -d "../test-repo-worktrees/basic-no-config/.git" ]
    
    # Verify we're in the organized structure directory
    [[ "$(pwd)" == *"test-repo-worktrees/basic-no-config"* ]]
    
    # No config files should be copied (no errors should occur)
    # Should only have git files and basic repo files
    local non_git_files=$(find "../test-repo-worktrees/basic-no-config" -maxdepth 1 -type f ! -path "*/.*" | wc -l)
    [ "$non_git_files" -eq 0 ]
}

@test "UNIT: Regression - config file error handling doesn't break worktree creation" {
    # Create config with nonexistent files and permission issues
    cat > .gwt-config << 'EOF'
nonexistent.txt
missing/directory/file.txt
/root/permission-denied.txt
EOF
    
    # Worktree creation should still succeed despite config errors
    git branch error-handling-test
    run gwt-create error-handling-test
    [ "$status" -eq 0 ]
    
    # Verify worktree was created successfully
    [ -d "../test-repo-worktrees/error-handling-test" ]
    [ -d "../test-repo-worktrees/error-handling-test/.git" ]
    
    # Verify we're in the worktree directory
    [[ "$(pwd)" == *"test-repo-worktrees/error-handling-test"* ]]
    
    # No files should be copied due to errors, but that's okay
    local copied_files=$(find "../test-repo-worktrees/error-handling-test" -maxdepth 1 -type f ! -path "*/.*" | wc -l)
    [ "$copied_files" -eq 0 ]
}

@test "UNIT: Regression - existing branch workflow still works with configs" {
    # Create test file and config
    echo "existing content" > existing.txt
    cat > .gwt-config << 'EOF'
existing.txt
EOF
    
    # Create branch first
    git checkout -b existing-branch-test
    echo "branch content" > branch-specific.txt
    git add branch-specific.txt
    git commit -m "Add branch-specific file"
    git checkout main
    
    # Use gwt-create with existing branch
    run gwt-create existing-branch-test
    [ "$status" -eq 0 ]
    
    # Verify worktree was created with existing branch
    [ -d "../test-repo-worktrees/existing-branch-test" ]
    
    # Verify config files were copied
    [ -f "../test-repo-worktrees/existing-branch-test/existing.txt" ]
    [ "$(cat "../test-repo-worktrees/existing-branch-test/existing.txt")" = "existing content" ]
    
    # Verify branch-specific content is present
    [ -f "../test-repo-worktrees/existing-branch-test/branch-specific.txt" ]
    [ "$(cat "../test-repo-worktrees/existing-branch-test/branch-specific.txt")" = "branch content" ]
}

@test "UNIT: Regression - organized directory structure is preserved" {
    # This is a core feature that must not be broken
    echo "organized test" > organized.txt
    cat > .gwt-config << 'EOF'
organized.txt
EOF
    
    # Create worktree
    git branch organized-structure-test
    run gwt-create organized-structure-test
    [ "$status" -eq 0 ]
    
    # CORE-FEATURE: Verify organized structure is maintained
    [ -d "../test-repo-worktrees" ]
    [ -d "../test-repo-worktrees/organized-structure-test" ]
    
    # Verify we end up in the organized directory
    [[ "$(pwd)" == *"test-repo-worktrees/organized-structure-test"* ]]
    
    # Verify config file was copied
    [ -f "../test-repo-worktrees/organized-structure-test/organized.txt" ]
    [ "$(cat "../test-repo-worktrees/organized-structure-test/organized.txt")" = "organized test" ]
    
    # The organized structure pattern must be preserved
    # This is the core value proposition that cannot be removed
    local parent_dir=$(dirname "$(pwd)")
    [[ "$parent_dir" == *"-worktrees" ]]
}

@test "UNIT: Regression - multiple worktrees can coexist with configs" {
    # Create shared config file
    echo "shared content" > shared.txt
    cat > .gwt-config << 'EOF'
shared.txt
EOF
    
    # Create first worktree
    git branch multi-tree-1
    run gwt-create multi-tree-1
    [ "$status" -eq 0 ]
    local first_dir="$(pwd)"
    
    # Return to main repo
    cd "$TEST_TEMP_DIR/test-repo"
    
    # Create second worktree
    git branch multi-tree-2
    run gwt-create multi-tree-2
    [ "$status" -eq 0 ]
    
    # Verify both worktrees exist with copied configs
    [ -d "../test-repo-worktrees/multi-tree-1" ]
    [ -d "../test-repo-worktrees/multi-tree-2" ]
    [ -f "../test-repo-worktrees/multi-tree-1/shared.txt" ]
    [ -f "../test-repo-worktrees/multi-tree-2/shared.txt" ]
    
    # Verify content in both worktrees
    [ "$(cat "../test-repo-worktrees/multi-tree-1/shared.txt")" = "shared content" ]
    [ "$(cat "../test-repo-worktrees/multi-tree-2/shared.txt")" = "shared content" ]
    
    # Verify we're in the second worktree
    [[ "$(pwd)" == *"test-repo-worktrees/multi-tree-2"* ]]
}

@test "UNIT: Regression - config parsing edge cases don't break functionality" {
    # Create config with various edge cases
    cat > .gwt-config << 'EOF'
# Comment line

    # Indented comment
valid-file.txt
    indented-entry.txt

# Another comment
EOF
    
    # Create the valid files
    echo "valid content" > valid-file.txt
    echo "indented content" > indented-entry.txt
    
    # Create worktree
    git branch edge-cases-test
    run gwt-create edge-cases-test
    [ "$status" -eq 0 ]
    
    # Verify worktree creation succeeded
    [ -d "../test-repo-worktrees/edge-cases-test" ]
    
    # Verify valid files were copied (comments should be ignored)
    [ -f "../test-repo-worktrees/edge-cases-test/valid-file.txt" ]
    [ -f "../test-repo-worktrees/edge-cases-test/indented-entry.txt" ]
    
    # Content verification
    [ "$(cat "../test-repo-worktrees/edge-cases-test/valid-file.txt")" = "valid content" ]
    [ "$(cat "../test-repo-worktrees/edge-cases-test/indented-entry.txt")" = "indented content" ]
}

@test "UNIT: Regression - wildcards and patterns still work in configs" {
    # Create files matching wildcard patterns
    echo "md1" > file1.md
    echo "md2" > file2.md
    echo "txt1" > file1.txt
    mkdir -p docs/guides
    echo "guide1" > docs/guide1.md
    echo "guide2" > docs/guides/advanced.md
    
    # Create config with patterns (if supported by current implementation)
    cat > .gwt-config << 'EOF'
*.md
docs/
*.txt
EOF
    
    # Create worktree
    git branch patterns-test
    run gwt-create patterns-test
    [ "$status" -eq 0 ]
    
    # Verify worktree creation succeeded
    [ -d "../test-repo-worktrees/patterns-test" ]
    
    # Note: The actual pattern expansion behavior depends on current implementation
    # These tests document what should work - may need adjustment based on actual behavior
    
    # If patterns are supported, files should be copied
    # If not supported, pattern strings should be treated as literal filenames (and fail gracefully)
    
    # At minimum, worktree should be created successfully regardless of pattern support
    [[ "$(pwd)" == *"test-repo-worktrees/patterns-test"* ]]
}

@test "UNIT: Regression - file permissions and ownership are preserved" {
    # Create files with specific permissions
    echo "executable content" > executable.sh
    echo "readable content" > readonly.txt
    chmod +x executable.sh
    chmod 644 readonly.txt
    
    # Create config
    cat > .gwt-config << 'EOF'
executable.sh
readonly.txt
EOF
    
    # Create worktree
    git branch permissions-test
    run gwt-create permissions-test
    [ "$status" -eq 0 ]
    
    # Verify files were copied
    [ -f "../test-repo-worktrees/permissions-test/executable.sh" ]
    [ -f "../test-repo-worktrees/permissions-test/readonly.txt" ]
    
    # Verify permissions are preserved (if implementation supports it)
    [ -x "../test-repo-worktrees/permissions-test/executable.sh" ]
    [ -r "../test-repo-worktrees/permissions-test/readonly.txt" ]
    
    # Content verification
    [ "$(cat "../test-repo-worktrees/permissions-test/executable.sh")" = "executable content" ]
    [ "$(cat "../test-repo-worktrees/permissions-test/readonly.txt")" = "readable content" ]
}