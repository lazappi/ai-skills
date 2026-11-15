import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "skills" / "harvest-skills" / "scripts" / "prompt_patterns.py"
sys.path.insert(0, str(SCRIPT.parent))

from prompt_patterns import find_patterns, pattern_key  # noqa: E402


def test_pattern_key_normalises():
    assert pattern_key("Run the TESTS, then fix 3 failures", 4) == "run the tests then"


def test_groups_and_counts_projects():
    prompts = [
        ("Run the tests and fix failures", "alpha"),
        ("run the tests, then fix", "beta"),
        ("Run the tests and fix the lint", "beta"),
        ("Write a README for this", "alpha"),
    ]
    patterns = find_patterns(prompts, words=3, min_count=2)
    assert [p["pattern"] for p in patterns] == ["run the tests"]
    assert patterns[0]["count"] == 3
    assert patterns[0]["projects"] == 2


def test_skips_commands_and_short_prompts():
    prompts = [("/exit", "a")] * 5 + [("yes", "a")] * 5
    assert find_patterns(prompts, words=3, min_count=2) == []
    kept = find_patterns(prompts, words=3, min_count=2, min_words=1, include_commands=True)
    assert {p["pattern"] for p in kept} == {"exit", "yes"}


def test_cli_reads_jsonl_and_skips_bad_lines(tmp_path):
    history = tmp_path / "history.jsonl"
    lines = [json.dumps({"display": "Bump the version and update NEWS", "project": f"/x/{p}"}) for p in "abc"]
    lines += ["not json", json.dumps({"other": 1}), json.dumps(["a list"])]
    history.write_text("\n".join(lines) + "\n")
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(history)], capture_output=True, text=True, check=True
    )
    assert "3 uses" in result.stdout
    assert "3 projects" in result.stdout
    assert "bump the version and" in result.stdout


def test_cli_missing_file(tmp_path):
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(tmp_path / "nope.jsonl")], capture_output=True, text=True
    )
    assert result.returncode == 1
