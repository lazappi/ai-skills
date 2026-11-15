#!/usr/bin/env bash
# Tests for the git hooks in .githooks/
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAILS=0

fail() {
  echo "  FAIL: $*"
  FAILS=$((FAILS + 1))
}

test_gitmoji_skips_without_terminal() {
  if { : </dev/tty; } 2>/dev/null; then
    echo "  skipped: a terminal is attached"
    return
  fi
  local msg
  msg="$(mktemp)"
  echo "Original message" > "$msg"
  "$SRC/.githooks/prepare-commit-msg" "$msg" message || fail "hook exited non-zero without a terminal"
  [ "$(cat "$msg")" = "Original message" ] || fail "hook changed the message: $(cat "$msg")"
  rm -f "$msg"
}

test_pre_commit_calls_no_agent() {
  if grep -qE '(^|[^-])claude ' "$SRC/.githooks/pre-commit"; then
    fail "pre-commit calls claude"
  fi
}

TESTS="$(declare -F | awk '{print $3}' | grep '^test_')"
for t in $TESTS; do
  echo "$t"
  "$t"
done

if [ "$FAILS" -gt 0 ]; then
  echo "$FAILS failure(s)"
  exit 1
fi
echo "all hook tests passed"
