#!/usr/bin/env bash
# Link this repo's skills and global instructions into each agent tool.
#
# Usage: scripts/install.sh install|update|uninstall [--dry-run] [--remote]
#
# install    link skills and instructions, install the Claude Code plugins
# update     pull this repo (fast-forward only), install again, then update
#            the Claude Code plugins
# uninstall  remove only what install created (third-party plugins stay)
#
# --remote adds the lazappi marketplace from GitHub instead of this checkout,
# and leaves the repo's git hooks off (for machines that only use the skills).
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
# Gemini import line: spaces escaped, never quoted
GEMINI_LINE="@${GLOBAL// /\\ }"

REMOTE_SOURCE="lazappi/ai-skills"

DRY_RUN=0
REMOTE=0
CHANGES=0
PROBLEMS=0

usage() {
  echo "usage: $0 install|update|uninstall [--dry-run] [--remote]" >&2
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
  if [ -L "$path" ] && [ ! -e "$path" ]; then
    problem "$path is a dangling link to $(readlink "$path") (moved clone?), remove it and run again"
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
  local line="$GEMINI_LINE"
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
  [ "$REMOTE" -eq 0 ] || return 0
  if [ "$(git -C "$REPO" config core.hooksPath 2>/dev/null || true)" != ".githooks" ]; then
    echo "set git hooks path"
    act git -C "$REPO" config core.hooksPath .githooks
  fi
}

# True when Claude Code steps should run (checked once, warns once)
CLAUDE_OK=""
claude_enabled() {
  if [ -z "$CLAUDE_OK" ]; then
    CLAUDE_OK=yes
    if [ "${AI_SKILLS_SKIP_CLAUDE:-0}" = "1" ]; then
      CLAUDE_OK=no
    elif ! command -v claude >/dev/null 2>&1; then
      echo "warning: claude not found, skipping Claude Code steps" >&2
      CLAUDE_OK=no
    elif ! command -v jq >/dev/null 2>&1; then
      problem "jq not found, needed for the Claude Code steps"
      CLAUDE_OK=no
    fi
  fi
  [ "$CLAUDE_OK" = yes ]
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
  local markets_json wanted current
  markets_json="$(claude plugin marketplace list --json)"
  MARKETS="$(printf '%s\n' "$markets_json" | jq -r '.[].name')"
  PLUGINS="$(claude plugin list --json | jq -r '.[].id')"

  if [ "$REMOTE" -eq 1 ]; then
    wanted="$REMOTE_SOURCE"
  else
    wanted="$REPO"
  fi
  # A marketplace is matched by name, so check an existing one has the wanted source
  current="$(printf '%s\n' "$markets_json" |
    jq -r '.[] | select(.name == "lazappi") | .path // .repo // .url // ""')"
  if [ -n "$current" ] && [ "$current" != "$wanted" ]; then
    problem "the lazappi marketplace points at $current, not $wanted: run 'claude plugin marketplace remove lazappi' and install again"
  fi
  add_market lazappi "$wanted"
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

do_update() {
  if git -C "$REPO" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    echo "pull: $REPO"
    act git -C "$REPO" pull --ff-only
  else
    echo "warning: no upstream branch for $REPO, skipping pull" >&2
  fi
  do_install
  claude_enabled || return 0
  echo "update marketplace: lazappi"
  act claude plugin marketplace update lazappi
  local id
  for id in lazappi@lazappi $(grep -v '^#' "$REPO/plugins.txt" | awk 'NF {print $1}'); do
    echo "update plugin: $id"
    act claude plugin update "$id" || problem "could not update $id"
  done
  echo "restart Claude Code to load plugin updates"
}

# Remove a symlink only if it points at the given target
unlink_own() {
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    echo "remove link: $path"
    act rm "$path"
  fi
}

remove_gemini_import() {
  local path="$TARGET_HOME/.gemini/GEMINI.md"
  local line="$GEMINI_LINE"
  [ -f "$path" ] && [ ! -L "$path" ] && grep -qxF -- "$line" "$path" || return 0
  echo "remove import line: $path"
  CHANGES=$((CHANGES + 1))
  [ "$DRY_RUN" -eq 1 ] && return 0
  local rest
  rest="$(grep -vxF -- "$line" "$path" || true)"
  if [ -z "$rest" ]; then
    rm "$path"
  else
    printf '%s\n' "$rest" > "$path"
  fi
}

do_uninstall() {
  local path
  for path in "$TARGET_HOME"/.agents/skills/*; do
    [ -L "$path" ] || continue
    case "$(readlink "$path")" in
      "$REPO/skills/"*) echo "remove link: $path"; act rm "$path" ;;
    esac
  done
  unlink_own "$GLOBAL" "$TARGET_HOME/.codex/AGENTS.md"
  unlink_own "$GLOBAL" "$TARGET_HOME/.config/opencode/AGENTS.md"
  remove_gemini_import
  if [ "$(git -C "$REPO" config core.hooksPath 2>/dev/null || true)" = ".githooks" ]; then
    echo "unset git hooks path"
    act git -C "$REPO" config --unset core.hooksPath
  fi

  claude_enabled || return 0
  if claude plugin list --json | jq -r '.[].id' | grep -qxF lazappi@lazappi; then
    echo "uninstall plugin: lazappi@lazappi"
    act claude plugin uninstall lazappi@lazappi
  fi
  if claude plugin marketplace list --json | jq -r '.[].name' | grep -qxF lazappi; then
    echo "remove marketplace: lazappi"
    act claude plugin marketplace remove lazappi
  fi
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
  update) do_update ;;
  uninstall) do_uninstall ;;
  *) usage ;;
esac

if [ "$CHANGES" -eq 0 ] && [ "$PROBLEMS" -eq 0 ]; then
  echo "No changes"
fi
if [ "$PROBLEMS" -gt 0 ]; then
  echo "$PROBLEMS item(s) skipped, see above" >&2
  exit 1
fi
