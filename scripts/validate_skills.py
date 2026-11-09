# /// script
# requires-python = ">=3.12"
# dependencies = ["pyyaml"]
# ///
"""Skill checks that skills-ref does not cover.

Portable skills (skills/) are validated against the spec by skills-ref.
This script adds a 500-line limit, full name and description checks for
Claude-only wrappers (claude/skills/), and a check for names used twice.
"""

import argparse
import re
import sys
from pathlib import Path

import yaml

MAX_LINES = 500
MAX_NAME = 64
MAX_DESCRIPTION = 1024
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def read_frontmatter(skill_md: Path) -> dict | None:
    text = skill_md.read_text()
    if not text.startswith("---\n"):
        return None

    end = text.find("\n---", 4)
    if end == -1:
        return None

    data = yaml.safe_load(text[4:end])
    return data if isinstance(data, dict) else None


def check_skill(path: Path, portable: bool) -> list[str]:
    skill_md = path / "SKILL.md"
    if not skill_md.is_file():
        return [f"{skill_md}: missing SKILL.md"]

    errors = []
    lines = len(skill_md.read_text().splitlines())
    if lines > MAX_LINES:
        errors.append(f"{skill_md}: {lines} lines, keep SKILL.md under {MAX_LINES} lines")
    if portable:
        return errors

    meta = read_frontmatter(skill_md)
    if meta is None:
        return errors + [f"{skill_md}: missing or invalid YAML frontmatter"]

    name = meta.get("name")
    if not isinstance(name, str) or not NAME_RE.match(name) or len(name) > MAX_NAME:
        errors.append(
            f"{skill_md}: name {name!r} must be 1-{MAX_NAME} lowercase letters, digits and single hyphens"
        )
    elif name != path.name:
        errors.append(f"{skill_md}: name {name!r} does not match folder {path.name!r}")

    description = meta.get("description")
    if not isinstance(description, str) or not description.strip():
        errors.append(f"{skill_md}: description is required")
    elif len(description) > MAX_DESCRIPTION:
        errors.append(f"{skill_md}: description is {len(description)} characters, max {MAX_DESCRIPTION}")

    return errors


def skill_dirs(root: Path) -> list[Path]:
    return sorted(p.parent for p in root.glob("*/SKILL.md"))


def check_duplicates(dirs: list[Path]) -> list[str]:
    seen: dict[str, list[Path]] = {}
    for root in dirs:
        for skill in skill_dirs(root):
            seen.setdefault(skill.name, []).append(skill)

    return [
        f"skill name {name!r} is used more than once: " + ", ".join(str(p) for p in paths)
        for name, paths in sorted(seen.items())
        if len(paths) > 1
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("skills_dir", type=Path, help="portable skills folder")
    parser.add_argument("--claude-dir", type=Path, help="Claude-only wrapper skills folder")
    args = parser.parse_args()

    errors = [e for s in skill_dirs(args.skills_dir) for e in check_skill(s, portable=True)]
    dirs = [args.skills_dir]
    if args.claude_dir:
        errors += [e for s in skill_dirs(args.claude_dir) for e in check_skill(s, portable=False)]
        dirs.append(args.claude_dir)
    errors += check_duplicates(dirs)

    for error in errors:
        print(error, file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
