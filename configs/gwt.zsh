# Git Worktree Management Functions

gwt-create() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: gwt-create <branch-name> [base-branch]"
    echo "Example: gwt-create ja/6588-service-accounts-ui"
    echo "         gwt-create ja/sub-feature ja/7529-local-langfuse"
    echo "Creates worktree at: ../<parent-dir>-worktrees/<branch-name>"
    return 1
  fi

  local branch_name="$1"
  local base_branch="$2"
  local parent_dir=$(basename "$PWD")
  local worktree_path="../${parent_dir}-worktrees/${branch_name}"

  # If base branch is provided, validate it exists
  if [[ -n "$base_branch" ]]; then
    if ! git rev-parse --verify "$base_branch" &>/dev/null; then
      echo "Error: Base branch '$base_branch' does not exist"
      return 1
    fi

    echo "Creating worktree from base branch: $base_branch"
    if git worktree add -b "$branch_name" "$worktree_path" "$base_branch"; then
      echo "Created worktree with new branch: $worktree_path"
    else
      echo "Error: Failed to create worktree from $base_branch"
      return 1
    fi
  else
    # Original behavior: try to create worktree with new branch first
    if git worktree add -b "$branch_name" "$worktree_path"; then
      echo "Created worktree with new branch: $worktree_path"
    # If that fails, try checking out existing branch
    elif git worktree add "$worktree_path" "$branch_name"; then
      echo "Created worktree from existing branch: $worktree_path"
    else
      echo "Error: Failed to create worktree"
      return 1
    fi
  fi

  # Change into worktree directory
  cd "$worktree_path" || return 1

  # Install dependencies
  echo "Running yarn install..."
  if ! yarn install; then
    echo "Error: yarn install failed"
    return 1
  fi

  # Run prepare script
  echo "Running yarn prepare..."
  if ! yarn prepare; then
    echo "Error: yarn prepare failed"
    return 1
  fi

  # Run build step for monorepo dependencies
  echo "Running yarn build..."
  if ! yarn build; then
    echo "Error: yarn build failed"
    return 1
  fi

  echo "Worktree setup complete!"
}

# Like gwt-create, but applies the personal fast-tests overlay from
# ~/.physna-fast-tests/ before installing deps. Safe to experiment with;
# leaves gwt-create's proven flow unchanged.
gwt-create-fast() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: gwt-create-fast <branch-name> [base-branch]"
    echo "Like gwt-create, plus applies ~/.physna-fast-tests/ overlay for fast tests."
    return 1
  fi

  local branch_name="$1"
  local base_branch="$2"
  local parent_dir=$(basename "$PWD")
  local worktree_path="../${parent_dir}-worktrees/${branch_name}"

  if [[ -n "$base_branch" ]]; then
    if ! git rev-parse --verify "$base_branch" &>/dev/null; then
      echo "Error: Base branch '$base_branch' does not exist"
      return 1
    fi
    echo "Creating worktree from base branch: $base_branch"
    if git worktree add -b "$branch_name" "$worktree_path" "$base_branch"; then
      echo "Created worktree with new branch: $worktree_path"
    else
      echo "Error: Failed to create worktree from $base_branch"
      return 1
    fi
  else
    if git worktree add -b "$branch_name" "$worktree_path"; then
      echo "Created worktree with new branch: $worktree_path"
    elif git worktree add "$worktree_path" "$branch_name"; then
      echo "Created worktree from existing branch: $worktree_path"
    else
      echo "Error: Failed to create worktree"
      return 1
    fi
  fi

  cd "$worktree_path" || return 1

  # Apply personal fast-tests overlay; this runs its own yarn install.
  if [[ -x "$HOME/.physna-fast-tests/apply.sh" && -f "$HOME/.physna-fast-tests/manifest.tsv" ]]; then
    echo "Applying fast-tests overlay..."
    if ! "$HOME/.physna-fast-tests/apply.sh"; then
      echo "Error: fast-tests overlay apply failed"
      return 1
    fi
  else
    echo "Warning: ~/.physna-fast-tests/apply.sh not installed; falling back to yarn install"
    if ! yarn install; then
      echo "Error: yarn install failed"
      return 1
    fi
  fi

  echo "Running yarn prepare..."
  if ! yarn prepare; then
    echo "Error: yarn prepare failed"
    return 1
  fi

  echo "Running yarn build..."
  if ! yarn build; then
    echo "Error: yarn build failed"
    return 1
  fi

  echo "Worktree setup complete (fast-tests overlay applied)!"
}

# Checkout existing remote branch in worktree
gwt-checkout() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: gwt-checkout <remote-branch-name>"
    echo "Example: gwt-checkout feature/user-authentication"
    echo "Creates worktree at: ../<parent-dir>-worktrees/<branch-name>"
    return 1
  fi

  local branch_name="$1"
  local parent_dir=$(basename "$PWD")
  local worktree_path="../${parent_dir}-worktrees/${branch_name}"

  # Fetch latest from remote
  echo "Fetching from origin..."
  if ! git fetch origin; then
    echo "Error: Failed to fetch from origin"
    return 1
  fi

  # Check if branch exists on remote
  if ! git rev-parse --verify "origin/$branch_name" &>/dev/null; then
    echo "Error: Branch '$branch_name' does not exist on origin"
    echo "Available remote branches:"
    git branch -r | grep -v HEAD
    return 1
  fi

  # Create worktree with local tracking branch
  echo "Creating worktree with tracking branch: $branch_name -> origin/$branch_name"
  if ! git worktree add --track -b "$branch_name" "$worktree_path" "origin/$branch_name"; then
    echo "Error: Failed to create worktree"
    return 1
  fi

  echo "Created worktree with tracking branch: $worktree_path"

  # Change into worktree directory
  cd "$worktree_path" || return 1

  # Install dependencies
  echo "Running yarn install..."
  if ! yarn install; then
    echo "Error: yarn install failed"
    return 1
  fi

  # Run prepare script
  echo "Running yarn prepare..."
  if ! yarn prepare; then
    echo "Error: yarn prepare failed"
    return 1
  fi

  # Run build step for monorepo dependencies
  echo "Running yarn build..."
  if ! yarn build; then
    echo "Error: yarn build failed"
    return 1
  fi

  echo "Worktree setup complete!"
}

# Cleanup worktree
gwt-cleanup() {
  # Get current worktree path
  local current_worktree=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$current_worktree" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Find the main repo directory
  local main_repo=$(git worktree list --porcelain | grep "^worktree" | head -1 | cut -d' ' -f2)

  if [[ -z "$main_repo" ]]; then
    echo "Error: Could not find main repository"
    return 1
  fi

  # Check if we're in the main repo (don't delete that!)
  if [[ "$current_worktree" == "$main_repo" ]]; then
    echo "Error: You are in the main repository. This command only removes worktrees."
    echo "Use 'gwt-list' to see available worktrees."
    return 1
  fi

  # Navigate to main repo
  echo "Removing worktree: $current_worktree"
  cd "$main_repo" || return 1

  # Remove the worktree
  if git worktree remove "$current_worktree"; then
    echo "Successfully removed worktree: $current_worktree"
    echo "You are now in: $main_repo"
  else
    echo "Error: Failed to remove worktree"
    echo "Try running: git worktree remove --force \"$current_worktree\""
    return 1
  fi
}

# List worktrees
gwt-list() {
  git worktree list
}

# Remove worktree
gwt-remove() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: gwt-remove <path>"
    return 1
  fi

  local worktree_path="$1"

  if git worktree remove "$worktree_path"; then
    echo "Removed worktree: $worktree_path"
  else
    echo "Error: Failed to remove worktree"
    return 1
  fi
}

# Repair orphaned worktree reference
gwt-repair() {
  git worktree repair
}

# Display worktree status dashboard
gwt-status() {
  local current_path=$(git rev-parse --show-toplevel 2>/dev/null)
  local main_repo=$(git worktree list --porcelain | grep "^worktree" | head -1 | awk '{print $2}')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "                        GIT WORKTREE DASHBOARD"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local worktree_path=""
  local branch=""
  local commit=""
  local is_bare=false
  local is_detached=false
  local is_prunable=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree ]]; then
      if [[ -n "$worktree_path" ]]; then
        local display_path="${worktree_path/#$HOME/~}"
        [[ "$worktree_path" == "$main_repo" ]] && display_path="$display_path (main)"
        [[ "$worktree_path" == "$current_path" ]] && display_path="$display_path <- YOU ARE HERE"

        local branch_display="$branch"
        [[ $is_detached == true ]] && branch_display="(detached HEAD)"
        [[ -z "$branch" && $is_bare == true ]] && branch_display="(bare)"

        local status_indicator=""
        if [[ $is_bare == false && -d "$worktree_path" ]]; then
          pushd "$worktree_path" >/dev/null 2>&1
          if [[ $? -eq 0 ]]; then
            local git_status=$(git status --porcelain 2>/dev/null)
            [[ -n "$git_status" ]] && status_indicator="DIRTY"

            local ahead_behind=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
            if [[ -n "$ahead_behind" ]]; then
              local behind=$(echo "$ahead_behind" | awk '{print $1}')
              local ahead=$(echo "$ahead_behind" | awk '{print $2}')
              [[ "$ahead" -gt 0 ]] && status_indicator="$status_indicator ↑$ahead"
              [[ "$behind" -gt 0 ]] && status_indicator="$status_indicator ↓$behind"
            fi
            popd >/dev/null 2>&1
          fi
        fi

        if [[ $is_prunable == true ]]; then
          echo "WARNING: PRUNABLE"
        fi

        echo "  $display_path"
        echo "   -> $branch_display"
        [[ -n "$commit" ]] && echo "   @ $commit"
        [[ -n "$status_indicator" ]] && echo "   $status_indicator"
        echo ""
      fi

      worktree_path="${line#worktree }"
      branch=""
      commit=""
      is_bare=false
      is_detached=false
      is_prunable=false
    elif [[ "$line" =~ ^HEAD ]]; then
      commit="${line#HEAD }"
      commit="${commit:0:8}"
    elif [[ "$line" =~ ^branch ]]; then
      branch="${line#branch }"
      branch="${branch##*/}"
    elif [[ "$line" == "bare" ]]; then
      is_bare=true
    elif [[ "$line" == "detached" ]]; then
      is_detached=true
    elif [[ "$line" == "prunable" ]]; then
      is_prunable=true
    fi
  done < <(git worktree list --porcelain)

  # Print last worktree
  if [[ -n "$worktree_path" ]]; then
    local display_path="${worktree_path/#$HOME/~}"
    [[ "$worktree_path" == "$main_repo" ]] && display_path="$display_path (main)"
    [[ "$worktree_path" == "$current_path" ]] && display_path="$display_path <- YOU ARE HERE"

    local branch_display="$branch"
    [[ $is_detached == true ]] && branch_display="(detached HEAD)"
    [[ -z "$branch" && $is_bare == true ]] && branch_display="(bare)"

    local status_indicator=""
    if [[ $is_bare == false && -d "$worktree_path" ]]; then
      pushd "$worktree_path" >/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        local git_status=$(git status --porcelain 2>/dev/null)
        [[ -n "$git_status" ]] && status_indicator="DIRTY"

        local ahead_behind=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
        if [[ -n "$ahead_behind" ]]; then
          local behind=$(echo "$ahead_behind" | awk '{print $1}')
          local ahead=$(echo "$ahead_behind" | awk '{print $2}')
          [[ "$ahead" -gt 0 ]] && status_indicator="$status_indicator ↑$ahead"
          [[ "$behind" -gt 0 ]] && status_indicator="$status_indicator ↓$behind"
        fi
        popd >/dev/null 2>&1
      fi
    fi

    if [[ $is_prunable == true ]]; then
      echo "WARNING: PRUNABLE"
    fi

    echo "  $display_path"
    echo "   -> $branch_display"
    [[ -n "$commit" ]] && echo "   @ $commit"
    [[ -n "$status_indicator" ]] && echo "   $status_indicator"
    echo ""
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Commands: gwt-create | gwt-checkout | gwt-cleanup | gwt-list | gwt-remove | gwt-repair"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
