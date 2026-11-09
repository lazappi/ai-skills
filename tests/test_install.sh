#!/usr/bin/env bash
# Tests for scripts/install.sh. Each test uses a temp copy of the repo and a
# temp home, both with a space in their path, so the real setup is never touched.
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0
TMP_ROOT=""

setup() {
  TMP_ROOT="$(mktemp -d)"
  export AI_SKILLS_REPO="$TMP_ROOT/repo copy"
  export AI_SKILLS_HOME="$TMP_ROOT/home dir"
  export AI_SKILLS_SKIP_CLAUDE=1
  mkdir -p "$AI_SKILLS_HOME"
  cp -R "$SRC" "$AI_SKILLS_REPO"
  mkdir -p "$AI_SKILLS_REPO/skills/zz-test-skill"
  printf -- '---\nname: zz-test-skill\ndescription: Throwaway test skill.\n---\n' \
    > "$AI_SKILLS_REPO/skills/zz-test-skill/SKILL.md"
}

teardown() {
  rm -rf "$TMP_ROOT"
}

install_sh() {
  "$AI_SKILLS_REPO/scripts/install.sh" "$@"
}

fail() {
  echo "  FAIL: $*"
  FAILS=$((FAILS + 1))
}

assert_link() {
  local link="$1" target="$2"
  if [ ! -L "$link" ]; then
    fail "$link is not a symlink"
  elif [ "$(readlink "$link")" != "$target" ]; then
    fail "$link points to $(readlink "$link"), expected $target"
  fi
}

gemini_line() {
  local escaped="${AI_SKILLS_REPO// /\\ }"
  echo "@$escaped/instructions/global.md"
}

test_creates_links() {
  install_sh install >/dev/null || fail "install exited non-zero"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
  assert_link "$AI_SKILLS_HOME/.codex/AGENTS.md" "$AI_SKILLS_REPO/instructions/global.md"
  assert_link "$AI_SKILLS_HOME/.config/opencode/AGENTS.md" "$AI_SKILLS_REPO/instructions/global.md"
  local gemini="$AI_SKILLS_HOME/.gemini/GEMINI.md"
  if [ -L "$gemini" ]; then
    fail "GEMINI.md must be a real file, not a symlink"
  elif [ "$(head -n 1 "$gemini" 2>/dev/null)" != "$(gemini_line)" ]; then
    fail "GEMINI.md first line is '$(head -n 1 "$gemini" 2>/dev/null)', expected '$(gemini_line)'"
  fi
  [ "$(git -C "$AI_SKILLS_REPO" config core.hooksPath)" = ".githooks" ] || fail "core.hooksPath not set"
}

test_idempotent() {
  install_sh install >/dev/null
  local out
  out="$(install_sh install)" || fail "second install exited non-zero"
  echo "$out" | grep -q "No changes" || fail "second install made changes: $out"
}

test_refuses_real_file() {
  mkdir -p "$AI_SKILLS_HOME/.codex"
  echo "my own rules" > "$AI_SKILLS_HOME/.codex/AGENTS.md"
  local out
  if out="$(install_sh install 2>&1)"; then
    fail "install should exit non-zero when a real file is in the way"
  fi
  [ "$(cat "$AI_SKILLS_HOME/.codex/AGENTS.md")" = "my own rules" ] || fail "real file was changed"
  echo "$out" | grep -q ".codex/AGENTS.md" || fail "output does not name the file: $out"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
}

test_prunes_stale() {
  install_sh install >/dev/null
  rm -r "$AI_SKILLS_REPO/skills/zz-test-skill"
  install_sh install >/dev/null || fail "install exited non-zero"
  if [ -L "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" ]; then
    fail "stale link was not removed"
  fi
}

test_dry_run() {
  install_sh install --dry-run >/dev/null || fail "dry run exited non-zero"
  if [ -e "$AI_SKILLS_HOME/.agents" ] || [ -e "$AI_SKILLS_HOME/.gemini" ] || [ -e "$AI_SKILLS_HOME/.codex" ]; then
    fail "dry run changed the home folder"
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
echo "all install tests passed"
