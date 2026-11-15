#!/usr/bin/env bash
# Shared helpers for the shell tests. Source this file, don't run it.

# Copy the repo's publishable files (tracked plus untracked, not ignored) into
# a fresh git repo with no remote, so tests never reach the real upstream and
# never pick up build or eval output.
copy_repo() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  (
    cd "$src"
    git ls-files --cached --others --exclude-standard -z |
      while IFS= read -r -d '' f; do
        [ -e "$f" ] && printf '%s\0' "$f"
      done |
      tar --null -T - -cf -
  ) | tar -xf - -C "$dest"
  git -C "$dest" init -q
}
