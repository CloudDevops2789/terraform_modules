#!/usr/bin/env bash
# 1. Sync with remote and remove stale remote tracking refs
git fetch --prune

# 2. Loop through all local branches
for branch in $(git branch --format="%(refname:short)"); do
  # Skip the current branch and any branches you want to keep (e.g., main, master)
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    continue
  fi

  # Check if a remote tracking branch exists for this local branch
  if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "Deleting local branch: $branch (no remote counterpart)"
    git branch -D "$branch"
  fi
done