---
name: harvest-skills
description: Harvest reusable skills from a user's existing instructions and usage across many projects, by mining instruction files, existing skills and prompt history for repeated rules and workflows, then proposing ranked skill candidates for approval before drafting any. Use when the user asks which of their instructions or habits should become skills, what workflows they repeat across repos, or to mine their prompt history for new skills.
---

# Harvest skills

Find what the user repeats across projects and turn the best of it into skill candidates.
The deliverable is a ranked shortlist: draft a skill only after the user picks it.

Everything you read here is private.
Use it as evidence for the user, and keep project names, paths, people and data out of any skill you draft, so the skill is safe to share.

## 1. Agree the scope

Ask the user, unless the request already says:

- Which code folders to search, and any projects to leave out
- Which tools they use, so you know which history to read
- Where new skills should go (a skills repo, `~/.claude/skills/` or one project)

Done when you know the folders, the tools and the destination.

## 2. Gather the evidence

Read [references/sources.md](references/sources.md) for where each tool keeps instructions, skills and history.

1. Collect the global instructions and every project instruction file in scope
2. List the skills, commands, subagents and plugins already installed, with their descriptions
3. Run the prompt history through the bundled script:

   ```bash
   python3 scripts/prompt_patterns.py ~/.claude/history.jsonl
   ```

   It prints prompt patterns used three or more times, ranked by how many projects they appear in.
   Lower `--min-count` for a short history, and raise `--words` to split a broad pattern.
4. For promising patterns, search the session transcripts for how the work actually went: the steps taken, the corrections the user made, the commands that were repeated

Done when every instruction file in scope has been read and the history has been run through the script.

## 3. Find candidates

Look for these, strongest first:

- **Rules repeated across projects**: the same convention written into two or more instruction files
- **Repeated workflows**: a prompt pattern used in several projects, or a multi-step procedure the user walks the agent through again and again
- **Repeated corrections**: the user fixing the same agent behaviour in different sessions
- **Project skills worth generalising**: a project skill or subagent whose core would help elsewhere

Leave out one-off tasks, project-specific facts and rules that belong in global instructions because they apply to every reply.
Recommend global instructions for those instead.
Done when each candidate has its evidence: counts, the projects or sessions it came from and the steps it repeats.

## 4. Check what already exists

For each candidate, compare it with the installed skills and plugins from step 2.
Drop it when an existing skill already does the job, or propose a change to that skill when the candidate fills a gap in it.
Keep it only when you can state what it adds over the closest existing skill in one line.
Done when every candidate has an "adds over" line or has been dropped.

## 5. Propose, then wait

Present a table, most valuable first:

| Candidate | Kind | Evidence | Adds over |
| - | - | - | - |
| `release-notes` | New skill | 14 prompts in 5 projects, same 4 steps each time | `commit-commands` only writes single commits |
| Air formatting rule | Global instruction | In 3 of 4 R projects' `CLAUDE.md` | Applies everywhere, too short for a skill |

Kind is one of new skill, change to an existing skill, global instruction or script.
Describe evidence with counts and the kind of project, not names or quotes the user might not want repeated.
Then stop and ask which candidates to draft.

## 6. Draft the approved skills

- Follow the destination's own rules for writing skills (its `AGENTS.md` or contributing guide), or the Agent Skills spec when it has none
- Write the description first, using the words the user actually typed in the matching prompts
- Generalise: replace project names, paths and data with placeholders or leave them out
- Add a few trigger test prompts (should fire and should not fire) when the destination has an eval setup
- Leave everything uncommitted unless the user asks for a commit

Report each new or changed file and the candidates you left for later.
