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
    name="${name%/}"
    case "$name" in
      "" | *[!a-z0-9-]*)
        echo "error: '$name' is not a skill name (lowercase letters, digits and hyphens)" >&2
        exit 1
        ;;
    esac
    if [ ! -f "$REPO/skills/$name/SKILL.md" ]; then
      echo "error: no portable skill named '$name' in skills/" >&2
      exit 1
    fi
    names="$names $name"
  done
else
  for skill in "$REPO"/skills/*/; do
    [ -f "${skill}SKILL.md" ] && names="$names $(basename "$skill")"
  done
fi

mkdir -p "$DIST"
# Names are checked above (no spaces or globs), so word splitting is safe here
for name in $names; do
  rm -f "$DIST/$name.zip"
  (cd "$REPO/skills" && uv run --quiet python - "$DIST/$name.zip" "$name" <<'PY'
import sys
import zipfile
from pathlib import Path

# Zip the skill folder, leaving out dotfiles such as .DS_Store
out, name = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(Path(name).rglob("*")):
        if path.is_file() and not any(part.startswith(".") for part in path.parts):
            zf.write(path)
PY
  )
  echo "built: dist/$name.zip"
done
