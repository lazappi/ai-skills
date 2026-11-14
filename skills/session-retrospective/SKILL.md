---
name: session-retrospective
description: Retrospective on the current session that turns its lessons into proposed edits to project instructions, skills, scripts and memory, applied after the user approves. Use when the user asks to review the session or say what was learned, to find repeated commands that could become scripts, or to update an improvements file from the session.
---

# Session retrospective

Turn the lessons of this session into durable improvements, so the next session starts where this one ended.
The output is a short list of proposed changes, applied once the user approves them.

## 1. Gather evidence

Work from the session itself, not from general advice.
Scan the conversation for:

- **Corrections**: places the user said "no", "don't", "instead", "again" or undid your work.
  Each one is a rule the instructions failed to state.
- **Repeated work**: the same command sequence, lookup or multi-step manual process done two or more times.
  These are candidates for a script or a recipe in the project's task runner.
- **Friction**: errors you hit and worked around, missing context you had to discover, permission prompts, slow or expensive steps.
- **Surprises**: behaviour of the codebase, tools or data that wasn't documented and that a future session would also trip over.
- **What worked**: approaches the user explicitly approved, which are worth keeping as defaults.

Note where each lesson came from (the request, the error, the user's words) so the proposal can cite it.
Done when every correction and every repeated sequence in the session is either a lesson or consciously dropped.

## 2. Check what already exists

Before proposing anything, read the places it would go:

- Project instructions (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or the tool's equivalent) and any files they import
- Skills and commands in the project and the user's personal skill folders
- Scripts, task runner files (`justfile`, `Makefile`, `package.json` scripts) and docs
- Memory files or lesson logs, if the tool or project keeps them
- Any improvements file the user named (for example `IMPROVEMENTS.md`)

Drop a lesson that is already covered.
Done when each remaining lesson has been checked against the files it would change.
If an existing rule was ignored rather than missing, propose making it clearer or enforcing it (a hook, a setting, a check script) instead of adding a duplicate.
If two existing rules conflict, flag the conflict.

## 3. Choose where each change belongs

| Kind of lesson | Where it goes |
| - | - |
| Applies to every session in this project | Project instructions file |
| A procedure that only matters for some tasks | A skill or command (new or existing) |
| A deterministic sequence of commands | A script or task runner recipe, referenced from the instructions |
| Must never be broken | A hook, setting or validation check, because instructions only ask |
| A fact about the user or their preferences across projects | Memory or the user's global instructions |
| Only true for this one session | Nowhere: leave it out |

Prefer the narrowest place that will reliably be read.
Keep the instructions file short: a long file gets skimmed, so move detail into skills or docs and link to it.

## 4. Propose, then wait

Present the proposals as a numbered list, most valuable first.
For each one give:

- **What**: the change, with the exact wording or a short diff for text edits
- **Where**: the file (or new file) it goes in
- **Why**: the evidence from this session, in one line

Group the list by destination when there are more than five items.
Keep it to changes worth making: three good proposals beat ten weak ones.
If the user named an improvements file, write the list there as well, merged with what is already in it rather than appended as a duplicate.

Then stop and ask which to apply.
Edit instructions, skills and scripts only after the user approves, because these files shape every future session and the user owns them.

## 5. Apply the approved changes

- Make only the approved edits
- For a new script or recipe, run it once to show it works
- For a new or changed skill, keep its description specific about when it should trigger
- Report what changed, file by file, and anything you skipped and why
- Leave the changes uncommitted unless the user asks for a commit
