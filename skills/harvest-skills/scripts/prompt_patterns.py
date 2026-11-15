#!/usr/bin/env python3
"""Find prompts a user repeats, across projects, in agent prompt history files.

Usage: prompt_patterns.py HISTORY.jsonl [...] [--min-count N] [--words N] [--top N]
                         [--min-words N] [--include-commands]

Each line of a history file is a JSON object. The prompt text is read from the
first of the fields "display", "prompt", "text" or "content" that holds a
string, and the project from "project", "cwd" or "directory". Lines that don't
parse or have no prompt are skipped, and so are slash commands ("/exit") and
prompts shorter than --min-words words, unless asked for.

Prompts are grouped by their first --words words (lowercased, punctuation and
numbers dropped), so "Run the tests and fix failures" and "run the tests, then
fix" land together. Output is plain text, most frequent patterns first, with the
number of uses, the number of distinct projects (by folder name) and up to three
shortened examples. Nothing is written to disk.
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

PROMPT_FIELDS = ("display", "prompt", "text", "content")
PROJECT_FIELDS = ("project", "cwd", "directory")
WORD_RE = re.compile(r"[a-z][a-z'/-]*")


def first_string(record: dict, fields: tuple[str, ...]) -> str | None:
    for field in fields:
        value = record.get(field)
        if isinstance(value, str) and value.strip():
            return value
    return None


def pattern_key(prompt: str, words: int) -> str:
    return " ".join(WORD_RE.findall(prompt.lower())[:words])


def read_prompts(paths: list[Path]):
    for path in paths:
        with path.open(encoding="utf-8", errors="replace") as handle:
            for line in handle:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(record, dict):
                    continue
                prompt = first_string(record, PROMPT_FIELDS)
                if prompt is None:
                    continue
                project = first_string(record, PROJECT_FIELDS) or ""
                yield prompt, Path(project).name if project else "(unknown)"


def find_patterns(
    prompts, words: int, min_count: int, min_words: int = 3, include_commands: bool = False
) -> list[dict]:
    groups: dict[str, dict] = defaultdict(lambda: {"count": 0, "projects": set(), "examples": []})
    for prompt, project in prompts:
        if not include_commands and prompt.lstrip().startswith("/"):
            continue
        if len(WORD_RE.findall(prompt.lower())) < min_words:
            continue
        key = pattern_key(prompt, words)
        if not key:
            continue
        group = groups[key]
        group["count"] += 1
        group["projects"].add(project)
        example = " ".join(prompt.split())[:100]
        if len(group["examples"]) < 3 and example not in group["examples"]:
            group["examples"].append(example)

    patterns = [
        {"pattern": key, "count": g["count"], "projects": len(g["projects"]), "examples": g["examples"]}
        for key, g in groups.items()
        if g["count"] >= min_count
    ]
    patterns.sort(key=lambda p: (-p["projects"], -p["count"], p["pattern"]))
    return patterns


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--min-count", type=int, default=3, help="minimum uses to report (default 3)")
    parser.add_argument("--words", type=int, default=4, help="leading words that define a pattern (default 4)")
    parser.add_argument("--top", type=int, default=40, help="patterns to print (default 40)")
    parser.add_argument("--min-words", type=int, default=3, help="skip shorter prompts (default 3)")
    parser.add_argument("--include-commands", action="store_true", help="keep slash commands")
    args = parser.parse_args()

    missing = [str(f) for f in args.files if not f.is_file()]
    if missing:
        print(f"error: not a file: {', '.join(missing)}", file=sys.stderr)
        return 1

    patterns = find_patterns(
        read_prompts(args.files), args.words, args.min_count, args.min_words, args.include_commands
    )
    if not patterns:
        print("No repeated prompts found")
        return 0
    for p in patterns[: args.top]:
        print(f"{p['count']:4d} uses  {p['projects']:3d} projects  {p['pattern']}")
        for example in p["examples"]:
            print(f"            - {example}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
