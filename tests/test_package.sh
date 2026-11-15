#!/usr/bin/env bash
# Tests for scripts/package.sh. Each test uses a temp copy of the repo with a
# space in its path, so the real dist/ is never touched.
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0
# shellcheck source=tests/helpers.sh
. "$SRC/tests/helpers.sh"
TMP_ROOT=""

setup() {
  TMP_ROOT="$(mktemp -d)"
  export AI_SKILLS_REPO="$TMP_ROOT/repo copy"
  copy_repo "$SRC" "$AI_SKILLS_REPO"
  add_skill skills zz-one
  add_skill skills zz-two
  add_skill claude/skills zz-wrapper
}

teardown() {
  rm -rf "$TMP_ROOT"
}

add_skill() {
  local dir="$AI_SKILLS_REPO/$1/$2"
  mkdir -p "$dir/references"
  printf -- '---\nname: %s\ndescription: Throwaway test skill.\n---\n' "$2" > "$dir/SKILL.md"
  echo "detail" > "$dir/references/detail.md"
  echo "junk" > "$dir/.DS_Store"
}

package_sh() {
  "$AI_SKILLS_REPO/scripts/package.sh" "$@"
}

fail() {
  echo "  FAIL: $*"
  FAILS=$((FAILS + 1))
}

zip_list() {
  uv run --quiet python -m zipfile -l "$1" | awk 'NR > 1 {print $1}'
}

test_packages_all_portable_skills() {
  package_sh >/dev/null || fail "package exited non-zero"
  local skill
  for skill in zz-one zz-two; do
    local zip="$AI_SKILLS_REPO/dist/$skill.zip"
    if [ ! -f "$zip" ]; then
      fail "missing $zip"
      continue
    fi
    zip_list "$zip" | grep -qxF "$skill/SKILL.md" || fail "$skill.zip has no $skill/SKILL.md: $(zip_list "$zip")"
    zip_list "$zip" | grep -qxF "$skill/references/detail.md" || fail "$skill.zip is missing references"
  done
}

test_skips_claude_wrappers() {
  package_sh >/dev/null
  [ ! -e "$AI_SKILLS_REPO/dist/zz-wrapper.zip" ] || fail "packaged a Claude-only wrapper"
}

test_named_skill_only() {
  package_sh zz-two >/dev/null || fail "package zz-two exited non-zero"
  [ -f "$AI_SKILLS_REPO/dist/zz-two.zip" ] || fail "zz-two.zip not built"
  [ ! -e "$AI_SKILLS_REPO/dist/zz-one.zip" ] || fail "zz-one.zip built when only zz-two was asked for"
}

test_unknown_skill_fails() {
  if package_sh zz-missing >/dev/null 2>&1; then
    fail "packaging an unknown skill should fail"
  fi
}

test_invalid_skill_aborts() {
  local i
  for i in $(seq 1 501); do echo "line $i"; done >> "$AI_SKILLS_REPO/skills/zz-one/SKILL.md"
  if package_sh >/dev/null 2>&1; then
    fail "package should fail when a skill is invalid"
  fi
  [ ! -e "$AI_SKILLS_REPO/dist" ] || [ -z "$(ls -A "$AI_SKILLS_REPO/dist")" ] || fail "zips built despite an invalid skill"
}

test_trailing_slash() {
  package_sh zz-two/ >/dev/null || fail "package zz-two/ exited non-zero"
  [ -f "$AI_SKILLS_REPO/dist/zz-two.zip" ] || fail "zz-two.zip not built from a name with a trailing slash"
}

test_rejects_bad_name() {
  if package_sh '../skills' >/dev/null 2>&1; then
    fail "packaging a name with a path should fail"
  fi
}

test_skips_dotfiles() {
  package_sh zz-one >/dev/null
  if zip_list "$AI_SKILLS_REPO/dist/zz-one.zip" | grep -q '\.DS_Store'; then
    fail "zip contains .DS_Store"
  fi
}

TESTS="$(declare -F | awk '{print $3}' | grep '^test_')"
for t in $TESTS; do
  echo "$t"
  setup
  "$t"
  teardown
done

if [ "$FAILS" -gt 0 ]; then
  echo "$FAILS failure(s)"
  exit 1
fi
echo "all package tests passed"
