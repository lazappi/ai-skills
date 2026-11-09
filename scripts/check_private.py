# /// script
# requires-python = ">=3.12"
# ///
"""Flag personal data (emails and home paths) in files git would publish.

Tokens and other secrets are left to gitleaks.
"""

import re
import subprocess
import sys
from pathlib import Path

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}")
HOME_RE = re.compile(r"/(?:Users|home)/([^/\s`'\")\]>]+|<[^>]*>)")

# Home folder names that are placeholders, not real users
PLACEHOLDER_NAMES = {"you", "user", "username", "example", "me", "shared", "runner"}

ALLOW = [
    re.compile(r"noreply@anthropic\.com"),
    re.compile(r"noreply@github\.com"),
]


def is_placeholder(name: str) -> bool:
    return name.startswith(("<", "$", "{")) or name.lower() in PLACEHOLDER_NAMES


def find_private(text: str, allow: list[re.Pattern]) -> list[tuple[int, str]]:
    found = []
    for number, line in enumerate(text.splitlines(), start=1):
        for match in EMAIL_RE.finditer(line):
            if not any(a.fullmatch(match.group()) for a in allow):
                found.append((number, match.group()))

        for match in HOME_RE.finditer(line):
            if not is_placeholder(match.group(1)):
                found.append((number, match.group()))

    return found


def publishable_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        capture_output=True,
        check=True,
        text=True,
    )
    return [Path(p) for p in result.stdout.split("\0") if p]


def main() -> int:
    problems = []
    for path in publishable_files():
        if not path.is_file():
            continue

        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue

        problems += [f"{path}:{number}: {match}" for number, match in find_private(text, ALLOW)]

    for problem in problems:
        print(problem, file=sys.stderr)

    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
