---
name: review-my-edits
description: Review my edits by finding the changes the user made by hand to files the agent wrote, following them through, resolving inline COMMENT markers and then running the next step. Use when the user says they have made edits, adjustments or changes and asks to check them, to read and fix the COMMENT lines they added, or to check their version and continue.
---

# Review my edits

The user has edited files by hand, often after reviewing your work.
Their edits are decisions: follow them, and treat inline markers as instructions.

## 1. Find the edits

Compare each file with the version you last wrote in this session.
Use `git status` and `git diff` for files you did not write, or when the session holds no earlier version.
List each edit with its file and line.

When an edit looks accidental (a stray deletion, a broken line, a change that contradicts the rest), ask about it before you act on it.
Done when every changed file is on the list.

## 2. Collect the markers

Search the changed files, and the files the user names, for inline feedback markers:

```bash
grep -rn "COMMENT:" <paths>
```

Use the marker the user names when it is not `COMMENT:`.
Read each marker with the code around it, and note when it applies to all similar files (for example "do this in every component").
Done when every marker is on the list with its scope.

## 3. Check the edits

Review each edit to ensure it is correct and makes sense in the context of the codebase.
If you find edits that are wrong, incomplete or inconsistent, ask the user what to do before you act on them.

## 4. Apply

1. Keep every intended edit exactly as the user wrote it
2. Follow each edit through: update tests, docs, configs and callers that depend on the changed code, and copy a changed pattern to the similar places the user did not reach
3. Resolve each marker, then delete the marker line
4. When a marker asks a question or the fix is unclear, answer it or ask, and leave that marker in place

When the user asks for suggestions only, report what you would change and leave the files as they are.
Done when no resolved marker is left in the files.

## 5. Run the next step

Run what the user asked for after the check, such as the tests, a render or the next phase of the plan.
When they asked for nothing, run the checks for the changed files following the project instructions.

Report:

- The edits you followed through and where
- Each marker and what you did about it
- The markers still open and why
- The check results
