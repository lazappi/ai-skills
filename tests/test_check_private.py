import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from check_private import ALLOW, find_private, publishable_files  # noqa: E402

# Build samples at runtime so this file never contains a match itself
EMAIL = "someone" + "@" + "example.org"
HOME = "/" + "Users" + "/" + "zz-fake"
LINUX_HOME = "/" + "home" + "/" + "zz-fake"


def test_flags_email():
    assert find_private(f"mail {EMAIL}", ALLOW) == [(1, EMAIL)]


def test_reports_line_number():
    assert find_private(f"first\nsecond {EMAIL}", ALLOW) == [(2, EMAIL)]


def test_flags_home_path():
    assert find_private(f"see {HOME}/notes", ALLOW)


def test_flags_home_without_slash():
    assert find_private(f"cd {HOME}", ALLOW)


def test_flags_linux_home():
    assert find_private(f"see {LINUX_HOME}/notes", ALLOW)


def test_ignores_placeholder_home():
    assert find_private("see /Users/<name>/notes and /home/you/x", ALLOW) == []


def test_ignores_tilde_paths():
    assert find_private("edit ~/.claude/CLAUDE.md", ALLOW) == []


def test_allowlist():
    assert find_private("noreply" + "@anthropic.com", ALLOW) == []


def test_publishable_files_skips_ignored(tmp_path, monkeypatch):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    (tmp_path / ".gitignore").write_text("ignored.txt\n")
    (tmp_path / "ignored.txt").write_text("x")
    (tmp_path / "untracked.txt").write_text("x")
    (tmp_path / "tracked.txt").write_text("x")
    subprocess.run(["git", "add", "tracked.txt"], cwd=tmp_path, check=True)
    monkeypatch.chdir(tmp_path)
    names = {p.name for p in publishable_files()}
    assert names == {".gitignore", "tracked.txt", "untracked.txt"}
