#!/usr/bin/env bash
# Build claude.ai upload zips for portable skills.
#
# Usage: scripts/package.sh [SKILL...]
#
# Writes dist/<name>.zip for each named skill, or for every skill in skills/
# when none are named. Each zip holds a top-level <name>/ folder.
# Claude-only wrappers in claude/skills/ are never packaged.
#
# Environment:
#   AI_SKILLS_REPO  repo root (default: the parent of scripts/)
set -euo pipefail

REPO="${AI_SKILLS_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
DIST="$REPO/dist"

uv run --quiet "$REPO/scripts/validate_skills.py" "$REPO/skills"

names=""
if [ $# -gt 0 ]; then
  for name in "$@"; do
    if [ ! -f "$REPO/skills/$name/SKILL.md" ]; then
      echo "error: no portable skill named '$name' in skills/" >&2
      exit 1
    fi
  done
  names="$*"
else
  for skill in "$REPO"/skills/*/; do
    [ -f "${skill}SKILL.md" ] && names="$names $(basename "$skill")"
  done
fi

mkdir -p "$DIST"
for name in $names; do
  rm -f "$DIST/$name.zip"
  (cd "$REPO/skills" && uv run --quiet python -m zipfile -c "$DIST/$name.zip" "$name")
  echo "built: dist/$name.zip"
done
