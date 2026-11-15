---
name: phase-review
description: Phase review that checks a finished phase of work against its plan or spec, writes severity-ranked findings to a review file, and later fixes the findings from that file. Use when the user asks to review phase N or a milestone against the plan, for a critical review of the implementation so far, or to read a review file and fix what it lists.
---

# Phase review

A phase review is an independent check that a finished phase does what its plan promised, without breaking earlier phases.
It has two modes:

- **Review**: read the plan and the work, then write the findings to a file
- **Fix**: work through a review file, resolving each finding

Pick the mode from the request.
If the user asks to review and then fix, write the review first, show the summary and wait before fixing.

## Review mode

### 1. Find the sources of truth

Locate and read:

- The plan, spec or ticket for this phase, and its acceptance criteria
- Earlier phases' plans and any existing files in `reviews/`
- Project instructions (`AGENTS.md`, `CLAUDE.md`), design records (ADRs, glossaries) and contributing guides
- Any reference implementation the plan names (another library, an earlier version, a spec document)

Ask the user which phase and plan to use when the request leaves it unclear.
Done when you can list every requirement this phase was meant to deliver.

### 2. Find the phase's changes

Identify the commits and uncommitted changes that belong to the phase, for example `git log` since the previous phase's tag or commit, `git diff` against it and `git status` for untracked files.
Read the changed files in full, so you judge each change in context.
Done when you have the complete list of files the phase touched.

### 3. Check the work

Work through each requirement and record whether it is met, partly met or missing, with the evidence.
Then check:

- **Completeness**: placeholders, stubs, `TODO`s, skipped tests or weakened assertions
- **Correctness**: behaviour matches the plan and the reference implementation, including errors and edge cases.
  Cite the reference as `path:line` when you claim a mismatch.
- **Earlier phases**: what earlier phases delivered still works
- **Tests**: new behaviour is tested, including failure paths
- **Consistency**: project conventions, terminology and design records are followed
- **Scope**: unrelated changes, or plan items quietly changed or dropped

Run the project's full checks (tests, linters, type checks) and record their results.
Done when every requirement has a verdict and every check above has been applied.

### 4. Write the review file

Write `reviews/<phase>-review.md`, for example `reviews/phase-2-review.md`, unless the project already keeps reviews elsewhere.
Use this structure:

```markdown
# Phase 2 review

Plan: docs/plan.md (phase 2)
Changes: abc1234..def5678 plus uncommitted work
Checks: tests pass (212), lint 3 warnings

## Summary

One paragraph verdict: ready, ready after fixes, or needs rework.

## Findings

### 1. [High] Short title

- **Where**: `R/read.R:42`
- **Problem**: what is wrong, with evidence
- **Expected**: what the plan or reference says (cite it)
- **Fix**: the change needed, or "Decision needed:" with the options

## Requirements

| Requirement | Status | Evidence |
| - | - | - |
```

Rank findings by severity, highest first:

- **High**: a requirement is unmet, behaviour is wrong or an earlier phase is broken
- **Medium**: missing tests, unhandled edge cases or divergence from conventions
- **Low**: clarity and maintainability improvements

Report real problems only, and leave style handled by the project's formatter or linter out.
Mark a finding "Decision needed" when the fix depends on a choice the plan does not settle.

Finish by giving the user the file path, the verdict and the count of findings by severity.
Leave the code unchanged in review mode.

## Fix mode

### 1. Read the review

Read the review file the user names, or the newest file in `reviews/` for the phase they mention.
List its findings with their severity and whether each is still open.
Done when every open finding is on the list.

### 2. Settle decisions first

Collect every finding marked "Decision needed", plus any where the fix is ambiguous or would change the plan.
Ask the user about all of them together, giving the options and your recommendation for each.
Done when every decision has an answer.

### 3. Fix in order of severity

For each finding:

1. Make the change
2. Add or update a test that would have caught the problem
3. Run the relevant tests

Done when every finding is fixed, settled by the user or explicitly deferred with a reason.

### 4. Record the outcome

Update the review file: mark each finding fixed, deferred or won't fix, with a one-line note.
Run the full test suite and checks, then report what changed, file by file, and anything left open.
Leave the changes uncommitted unless the user asks for a commit.
