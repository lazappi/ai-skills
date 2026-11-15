---
name: repo-tidy
description: Repository tidy-up audit that finds formatting, lint, dead code, stale docs, test gaps, config drift and duplication across the whole repo, and writes a prioritised checklist of fixes before changing anything. Use when the user asks to tidy or clean up a repo, to improve and simplify the whole codebase, or for a checklist of fixes to work through.
---

# Repo tidy

Audit the whole repository and turn what you find into a prioritised checklist.
The checklist is the deliverable: the user decides what gets fixed and when.

## 1. Learn the project's own standards

Read the project instructions (`AGENTS.md`, `CLAUDE.md`, contributing guides), the task runner (`justfile`, `Makefile`, `package.json` scripts) and the tool configs (formatter, linter, type checker, test runner, pre-commit, CI).
Judge the repo against these standards first, and against common practice for its language only where the project is silent.
Done when you know the commands for formatting, linting, testing and building, or know that one is missing.

## 2. Run the automated checks

Run the formatter in check mode, the linter, the type checker and the tests, without fixing anything.
Record each command and a summary of its output.
A check that fails to run is itself a finding.
Done when every check from step 1 has a recorded result.

## 3. Audit by area

Work through every area and record findings with `path:line` evidence:

- **Formatting and lint**: what the tools report, plus files the tools skip
- **Dead code**: unused functions, exports, files, dependencies and commented-out blocks.
  Confirm with a search before calling anything unused.
- **Duplication**: repeated logic that one shared function or module would replace
- **Simplification**: needless indirection, over-general abstractions and long functions with one clear split
- **Docs**: README steps that no longer work, out-of-date examples, missing docs for public interfaces
- **Tests**: untested public behaviour, skipped or flaky tests, slow tests that block the loop
- **Config**: settings that contradict each other, stale CI steps, pinned versions far behind, files that belong in `.gitignore`
- **Structure**: files in the wrong place and naming that breaks the project's conventions

Done when every area has been checked and has findings or a note that it is clean.

## 4. Write the checklist

Write `TIDY.md` at the repo root unless the user names another file or the project keeps such lists elsewhere.
If the file exists, merge with it rather than duplicating items.

```markdown
# Tidy checklist

Checks run: `just lint` (4 warnings), `just test` (pass, 98 tests)

## High

- [ ] Remove unused `parse_legacy()` (`src/io.py:120`), no callers since the v2 reader
- [ ] Fix README install step: `make setup` no longer exists

## Medium

- [ ] Merge the duplicated date parsing in `src/a.py:40` and `src/b.py:88`

## Low

- [ ] Rename `utils2.py` to match the module naming convention
```

Prioritise by value against effort:

- **High**: broken things (failing checks, wrong docs) and cheap wins with clear payoff
- **Medium**: duplication, missing tests and simplifications that touch several files
- **Low**: naming, structure and polish

Make each item one self-contained change with its evidence, so it can be done and checked off on its own.

## 5. Stop and report

Give the user the file path, the count of items by priority and the three most valuable items.
Leave the code unchanged until the user picks items to fix.
When they do, fix those items, run the checks again and tick them off in the checklist.
