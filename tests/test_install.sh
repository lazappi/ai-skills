#!/usr/bin/env bash
# Tests for scripts/install.sh. Each test uses a temp copy of the repo (a fresh
# git repo with no remote) and a temp home, both with a space in their path,
# so the real setup and the real upstream are never touched.
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0
# shellcheck source=tests/helpers.sh
. "$SRC/tests/helpers.sh"
TMP_ROOT=""
ORIG_PATH="$PATH"

setup() {
  export PATH="$ORIG_PATH"
  TMP_ROOT="$(mktemp -d)"
  export AI_SKILLS_REPO="$TMP_ROOT/repo copy"
  export AI_SKILLS_HOME="$TMP_ROOT/home dir"
  export AI_SKILLS_SKIP_CLAUDE=1
  mkdir -p "$AI_SKILLS_HOME"
  copy_repo "$SRC" "$AI_SKILLS_REPO"
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

use_stub() {
  unset AI_SKILLS_SKIP_CLAUDE
  export PATH="$AI_SKILLS_REPO/tests/bin:$PATH"
  export CLAUDE_STUB_LOG="$TMP_ROOT/claude.log"
  export CLAUDE_STUB_LIST="$TMP_ROOT/plugins.json"
  export CLAUDE_STUB_MARKETS="$TMP_ROOT/markets.json"
  echo "[]" > "$CLAUDE_STUB_LIST"
  echo "[]" > "$CLAUDE_STUB_MARKETS"
  : > "$CLAUDE_STUB_LOG"
}

third_party() {
  grep -v '^#' "$AI_SKILLS_REPO/plugins.txt" | grep -c .
}

test_claude_local() {
  use_stub
  install_sh install >/dev/null || fail "install exited non-zero"
  grep -qxF "plugin marketplace add $AI_SKILLS_REPO" "$CLAUDE_STUB_LOG" || fail "local marketplace not added"
  grep -qxF "plugin install lazappi@lazappi" "$CLAUDE_STUB_LOG" || fail "lazappi not installed"
  local installs
  installs="$(grep -c '^plugin install ' "$CLAUDE_STUB_LOG")"
  [ "$installs" -eq $(($(third_party) + 1)) ] || fail "expected $(($(third_party) + 1)) installs, got $installs"
  grep -qxF "plugin marketplace add anthropics/claude-plugins-official" "$CLAUDE_STUB_LOG" || fail "third-party marketplace not added"
  [ "$(grep -c '^plugin marketplace add anthropics/' "$CLAUDE_STUB_LOG")" -eq 1 ] || fail "third-party marketplace added more than once"
}

test_claude_remote() {
  use_stub
  install_sh install --remote >/dev/null || fail "install exited non-zero"
  grep -qxF "plugin marketplace add lazappi/ai-skills" "$CLAUDE_STUB_LOG" || fail "remote marketplace not added"
  if grep -qxF "plugin marketplace add $AI_SKILLS_REPO" "$CLAUDE_STUB_LOG"; then
    fail "local path added with --remote"
  fi
}

test_claude_skips_installed() {
  use_stub
  { echo '[{"id":"lazappi@lazappi"}'
    grep -v '^#' "$AI_SKILLS_REPO/plugins.txt" | awk 'NF {printf ",{\"id\":\"%s\"}", $1}'
    echo ']'; } > "$CLAUDE_STUB_LIST"
  printf '[{"name":"lazappi","path":"%s"},{"name":"claude-plugins-official"}]\n' "$AI_SKILLS_REPO" > "$CLAUDE_STUB_MARKETS"
  install_sh install >/dev/null || fail "install exited non-zero"
  if grep -qE '^plugin (install|marketplace add) ' "$CLAUDE_STUB_LOG"; then
    fail "installed or added something already present: $(grep -E '^plugin (install|marketplace add) ' "$CLAUDE_STUB_LOG" | head -3)"
  fi
}

test_no_claude() {
  unset AI_SKILLS_SKIP_CLAUDE
  local out
  out="$(PATH="/usr/bin:/bin:/usr/sbin:/sbin" install_sh install 2>&1)" || fail "install exited non-zero without claude"
  echo "$out" | grep -qi "claude not found" || fail "no warning about missing claude: $out"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
}

test_uninstall_only_own_links() {
  use_stub
  install_sh install >/dev/null
  echo '[{"id":"lazappi@lazappi"}]' > "$CLAUDE_STUB_LIST"
  echo '[{"name":"lazappi"}]' > "$CLAUDE_STUB_MARKETS"
  : > "$CLAUDE_STUB_LOG"
  ln -s "$TMP_ROOT" "$AI_SKILLS_HOME/.agents/skills/foreign"
  echo "my own gemini note" >> "$AI_SKILLS_HOME/.gemini/GEMINI.md"

  install_sh uninstall >/dev/null || fail "uninstall exited non-zero"

  [ -L "$AI_SKILLS_HOME/.agents/skills/foreign" ] || fail "foreign link was removed"
  for path in .agents/skills/zz-test-skill .codex/AGENTS.md .config/opencode/AGENTS.md; do
    if [ -e "$AI_SKILLS_HOME/$path" ] || [ -L "$AI_SKILLS_HOME/$path" ]; then
      fail "$path still exists after uninstall"
    fi
  done
  if grep -qxF "$(gemini_line)" "$AI_SKILLS_HOME/.gemini/GEMINI.md"; then
    fail "GEMINI.md still has the import line"
  fi
  grep -qxF "my own gemini note" "$AI_SKILLS_HOME/.gemini/GEMINI.md" || fail "GEMINI.md lost the user's own lines"
  grep -qxF "plugin uninstall lazappi@lazappi" "$CLAUDE_STUB_LOG" || fail "plugin not uninstalled"
  grep -qxF "plugin marketplace remove lazappi" "$CLAUDE_STUB_LOG" || fail "marketplace not removed"
}

test_uninstall_removes_empty_gemini() {
  install_sh install >/dev/null
  install_sh uninstall >/dev/null || fail "uninstall exited non-zero"
  if [ -e "$AI_SKILLS_HOME/.gemini/GEMINI.md" ]; then
    fail "GEMINI.md left behind with only the import line removed"
  fi
}

test_update_pulls_and_links() {
  local remote="$TMP_ROOT/remote.git" work="$TMP_ROOT/work"
  local email="test""@""test.invalid"
  local commit="git -c user.name=test -c user.email=$email -c commit.gpgsign=false"
  git -C "$AI_SKILLS_REPO" add -A >/dev/null
  $commit -C "$AI_SKILLS_REPO" commit -q --no-verify -m "test state" >/dev/null
  git clone -q --bare "$AI_SKILLS_REPO" "$remote"
  rm -rf "$AI_SKILLS_REPO"
  git clone -q "$remote" "$AI_SKILLS_REPO"
  install_sh install >/dev/null

  git clone -q "$remote" "$work"
  mkdir -p "$work/skills/zz-new-skill"
  printf -- '---\nname: zz-new-skill\ndescription: New skill.\n---\n' > "$work/skills/zz-new-skill/SKILL.md"
  git -C "$work" add -A
  $commit -C "$work" commit -q --no-verify -m "add skill"
  git -C "$work" push -q

  install_sh update >/dev/null || fail "update exited non-zero"
  [ -f "$AI_SKILLS_REPO/skills/zz-new-skill/SKILL.md" ] || fail "update did not pull the new commit"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-new-skill" "$AI_SKILLS_REPO/skills/zz-new-skill"
}

test_update_without_upstream() {
  local out
  out="$(install_sh update 2>&1)" || fail "update failed without an upstream: $out"
  echo "$out" | grep -qi "no upstream" || fail "no warning about the missing upstream: $out"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
}

test_gemini_without_import() {
  mkdir -p "$AI_SKILLS_HOME/.gemini"
  echo "my own gemini note" > "$AI_SKILLS_HOME/.gemini/GEMINI.md"
  local out
  if out="$(install_sh install 2>&1)"; then
    fail "install should exit non-zero when GEMINI.md lacks the import line"
  fi
  [ "$(cat "$AI_SKILLS_HOME/.gemini/GEMINI.md")" = "my own gemini note" ] || fail "GEMINI.md was changed"
  echo "$out" | grep -q "GEMINI.md exists without the import line" || fail "no message about GEMINI.md: $out"
}

test_refuses_foreign_link() {
  mkdir -p "$AI_SKILLS_HOME/.agents/skills"
  ln -s "$TMP_ROOT" "$AI_SKILLS_HOME/.agents/skills/zz-test-skill"
  if install_sh install >/dev/null 2>&1; then
    fail "install should exit non-zero when a foreign link is in the way"
  fi
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$TMP_ROOT"
}

test_reports_dangling_link() {
  mkdir -p "$AI_SKILLS_HOME/.agents/skills"
  ln -s "$TMP_ROOT/old clone/skills/zz-test-skill" "$AI_SKILLS_HOME/.agents/skills/zz-test-skill"
  local out
  if out="$(install_sh install 2>&1)"; then
    fail "install should exit non-zero for a dangling link"
  fi
  echo "$out" | grep -q "dangling link" || fail "no message about the dangling link: $out"
}

test_no_jq() {
  use_stub
  local bin="$TMP_ROOT/bin" tool
  mkdir -p "$bin"
  for tool in bash git mkdir ln readlink grep dirname basename rm cat head awk; do
    ln -s "$(command -v "$tool")" "$bin/$tool"
  done
  local out
  if out="$(PATH="$AI_SKILLS_REPO/tests/bin:$bin" install_sh install 2>&1)"; then
    fail "install should exit non-zero without jq"
  fi
  echo "$out" | grep -q "jq not found" || fail "no message about jq: $out"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
}

test_market_source_mismatch() {
  use_stub
  echo '[{"name":"lazappi","repo":"lazappi/ai-skills"}]' > "$CLAUDE_STUB_MARKETS"
  local out
  if out="$(install_sh install 2>&1)"; then
    fail "install should exit non-zero when the marketplace source differs"
  fi
  echo "$out" | grep -q "lazappi marketplace points at lazappi/ai-skills" || fail "no message about the source: $out"
}

test_remote_skips_hooks() {
  install_sh install --remote >/dev/null || fail "install --remote exited non-zero"
  [ -z "$(git -C "$AI_SKILLS_REPO" config core.hooksPath || true)" ] || fail "--remote set core.hooksPath"
}

test_uninstall_dry_run() {
  install_sh install >/dev/null
  install_sh uninstall --dry-run >/dev/null || fail "uninstall dry run exited non-zero"
  assert_link "$AI_SKILLS_HOME/.agents/skills/zz-test-skill" "$AI_SKILLS_REPO/skills/zz-test-skill"
  grep -qxF "$(gemini_line)" "$AI_SKILLS_HOME/.gemini/GEMINI.md" || fail "dry run removed the Gemini import line"
  [ "$(git -C "$AI_SKILLS_REPO" config core.hooksPath)" = ".githooks" ] || fail "dry run unset core.hooksPath"
}

test_uninstall_unsets_hooks() {
  install_sh install >/dev/null
  install_sh uninstall >/dev/null || fail "uninstall exited non-zero"
  [ -z "$(git -C "$AI_SKILLS_REPO" config core.hooksPath || true)" ] || fail "uninstall left core.hooksPath set"
}

test_update_updates_plugins() {
  use_stub
  install_sh update >/dev/null 2>&1 || fail "update exited non-zero"
  grep -qxF "plugin marketplace update lazappi" "$CLAUDE_STUB_LOG" || fail "marketplace not updated"
  grep -qxF "plugin update lazappi@lazappi" "$CLAUDE_STUB_LOG" || fail "lazappi plugin not updated"
  local updates
  updates="$(grep -c '^plugin update ' "$CLAUDE_STUB_LOG")"
  [ "$updates" -eq $(($(third_party) + 1)) ] || fail "expected $(($(third_party) + 1)) plugin updates, got $updates"
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
