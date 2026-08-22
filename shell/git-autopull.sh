#!/usr/bin/env bash
# ~/git-autopull.sh — pull every git repo under ~/git

GIT_DIR="$HOME/git"

for repo in "$GIT_DIR"/*/; do
    # Only process directories that are actually git repos
    if [ -d "$repo/.git" ]; then
        echo "==> Pulling ${repo}"
        git -C "$repo" pull --rebase
        echo
    fi
done
