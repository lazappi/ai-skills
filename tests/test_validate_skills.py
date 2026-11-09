import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from validate_skills import check_duplicates, check_skill  # noqa: E402

FIX = ROOT / "tests" / "fixtures" / "skills"
WRAPPERS = ROOT / "tests" / "fixtures" / "wrappers"


def write_skill(base: Path, folder: str, frontmatter: str) -> Path:
    skill = base / folder
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(f"---\n{frontmatter}---\n\n# Body\n")
    return skill


def test_valid_skill_passes():
    assert check_skill(FIX / "valid-skill", portable=True) == []


def test_claude_field_allowed_in_claude_dir():
    assert check_skill(FIX / "claude-field", portable=False) == []


def test_over_500_lines_rejected():
    errs = check_skill(FIX / "long-skill", portable=True)
    assert any("500" in e and "SKILL.md" in e for e in errs)


def test_wrapper_bad_name_rejected(tmp_path):
    skill = write_skill(tmp_path, "bad--name", "name: bad--name\ndescription: x\n")
    assert any("name" in e for e in check_skill(skill, portable=False))


def test_wrapper_name_must_match_folder(tmp_path):
    skill = write_skill(tmp_path, "folder", "name: other\ndescription: x\n")
    assert any("folder" in e for e in check_skill(skill, portable=False))


def test_wrapper_missing_description_rejected(tmp_path):
    skill = write_skill(tmp_path, "no-desc", "name: no-desc\n")
    assert any("description" in e for e in check_skill(skill, portable=False))


def test_missing_frontmatter_rejected(tmp_path):
    skill = tmp_path / "plain"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# No frontmatter\n")
    assert check_skill(skill, portable=False) != []


def test_duplicate_names_rejected():
    errs = check_duplicates([FIX, WRAPPERS])
    assert len(errs) == 1 and "dup-a" in errs[0]


def test_no_duplicates_in_one_dir():
    assert check_duplicates([FIX]) == []
