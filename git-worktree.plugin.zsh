#!/usr/bin/env zsh

# Git Worktree Zsh Plugin
# Oh My Zsh plugin wrapper for git-worktree.zsh

# Get the directory where this plugin file is located
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Source the main git worktree functions
source "${0:h}/git-worktree.zsh"