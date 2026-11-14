#!/usr/bin/env bash
# Link this repo's skills and global instructions into each agent tool.
#
# Usage: scripts/install.sh install [--dry-run] [--remote]
#
# --remote adds the lazappi marketplace from GitHub instead of this checkout.
#
# Environment:
#   AI_SKILLS_HOME        target home folder (default: $HOME)
#   AI_SKILLS_REPO        repo root (default: the parent of scripts/)
#   AI_SKILLS_SKIP_CLAUDE set to 1 to skip Claude Code steps
#
# Must run on bash 3.2 (macOS): no mapfile, no associative arrays.
set -euo pipefail

REPO="${AI_SKILLS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGET_HOME="${AI_SKILLS_HOME:-$HOME}"
GLOBAL="$REPO/instructions/global.md"

REMOTE_SOURCE="lazappi/ai-skills"

DRY_RUN=0
REMOTE=0
CHANGES=0
PROBLEMS=0

usage() {
  echo "usage: $0 install [--dry-run] [--remote]" >&2
  exit 2
}

# Run a command, or only print it in a dry run
act() {
  CHANGES=$((CHANGES + 1))
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "would run: $*"
  else
    "$@"
  fi
}

problem() {
  echo "skipped: $*" >&2
  PROBLEMS=$((PROBLEMS + 1))
}

# Create a symlink, leaving correct links alone and never replacing anything else
link() {
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    return
  fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    problem "$path already exists and is not a link to $target"
    return
  fi
  echo "link: $path -> $target"
  act mkdir -p "$(dirname "$path")"
  act ln -s "$target" "$path"
}

# Gemini appends memories to GEMINI.md, so it gets an import line, not a symlink
gemini_import() {
  local path="$TARGET_HOME/.gemini/GEMINI.md"
  local line="@${GLOBAL// /\\ }"
  if [ -f "$path" ] && [ ! -L "$path" ] && grep -qxF -- "$line" "$path"; then
    return
  fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    problem "$path exists without the import line '$line'"
    return
  fi
  echo "create: $path"
  act mkdir -p "$(dirname "$path")"
  if [ "$DRY_RUN" -eq 0 ]; then
    printf '%s\n' "$line" > "$path"
  fi
}

# Remove skill links that point into this repo at skills that no longer exist
prune_skills() {
  local dir="$TARGET_HOME/.agents/skills" path target
  [ -d "$dir" ] || return 0
  for path in "$dir"/*; do
    [ -L "$path" ] || continue
    target="$(readlink "$path")"
    case "$target" in
      "$REPO/skills/"*)
        if [ ! -e "$target" ]; then
          echo "remove stale link: $path"
          act rm "$path"
        fi
        ;;
    esac
  done
}

link_skills() {
  local skill name
  for skill in "$REPO"/skills/*/; do
    [ -f "${skill}SKILL.md" ] || continue
    name="$(basename "$skill")"
    link "$REPO/skills/$name" "$TARGET_HOME/.agents/skills/$name"
  done
}

git_hooks() {
  if [ "$(git -C "$REPO" config core.hooksPath 2>/dev/null || true)" != ".githooks" ]; then
    echo "set git hooks path"
    act git -C "$REPO" config core.hooksPath .githooks
  fi
}

# True when Claude Code steps should run
claude_enabled() {
  if [ "${AI_SKILLS_SKIP_CLAUDE:-0}" = "1" ]; then
    return 1
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "warning: claude not found, skipping Claude Code steps" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    problem "jq not found, needed for the Claude Code steps"
    return 1
  fi
}

# Newline-separated lists of what is already set up (bash 3.2 has no sets)
MARKETS=""
PLUGINS=""

has() {
  printf '%s\n' "$1" | grep -qxF -- "$2"
}

add_market() {
  local name="$1" source="$2"
  has "$MARKETS" "$name" && return 0
  echo "add marketplace: $name ($source)"
  act claude plugin marketplace add "$source"
  MARKETS="$MARKETS
$name"
}

add_plugin() {
  local id="$1"
  has "$PLUGINS" "$id" && return 0
  echo "install plugin: $id"
  act claude plugin install "$id"
  PLUGINS="$PLUGINS
$id"
}

claude_steps() {
  claude_enabled || return 0
  MARKETS="$(claude plugin marketplace list --json | jq -r '.[].name')"
  PLUGINS="$(claude plugin list --json | jq -r '.[].id')"

  if [ "$REMOTE" -eq 1 ]; then
    add_market lazappi "$REMOTE_SOURCE"
  else
    add_market lazappi "$REPO"
  fi
  add_plugin lazappi@lazappi

  local id source
  while read -r id source; do
    case "$id" in "" | "#"*) continue ;; esac
    add_market "${id#*@}" "$source"
    add_plugin "$id"
  done < "$REPO/plugins.txt"
}

do_install() {
  git_hooks
  link_skills
  prune_skills
  link "$GLOBAL" "$TARGET_HOME/.codex/AGENTS.md"
  link "$GLOBAL" "$TARGET_HOME/.config/opencode/AGENTS.md"
  gemini_import
  claude_steps
}

[ $# -ge 1 ] || usage
COMMAND="$1"
shift
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --remote) REMOTE=1 ;;
    *) usage ;;
  esac
done

case "$COMMAND" in
  install) do_install ;;
  *) usage ;;
esac

if [ "$CHANGES" -eq 0 ] && [ "$PROBLEMS" -eq 0 ]; then
  echo "No changes"
fi
if [ "$PROBLEMS" -gt 0 ]; then
  echo "$PROBLEMS item(s) skipped, see above" >&2
  exit 1
fi
