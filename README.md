# ai-skills

My personal skills and global instructions for AI coding agents.
Skills follow the [Agent Skills](https://agentskills.io) open standard, so the same files work in Claude Code, Codex, Gemini CLI, OpenCode and claude.ai.
In Claude Code the repo installs as the `lazappi` plugin.

## Install

In Claude Code:

```
/plugin install lazappi --marketplace lazappi/ai-skills
```

Instructions for other tools are added once the install script exists.

## Skills

| Skill | Use it for | Adds over |
| - | - | - |
| `phase-review` | Reviewing a finished phase against its plan into a severity-ranked review file, then fixing from it | `code-review`, which reviews diffs rather than a phase against its plan and writes no file |
| `r-package-dev` | Developing R packages with formatting, lint, roxygen2, testthat, NEWS.md, version and Bioconductor conventions | No existing skill covers R package conventions |
| `repo-tidy` | Auditing a whole repo into a prioritised checklist of fixes before changing anything | `simplify`, which only edits recently changed code |
| `session-retrospective` | Turning a session's lessons into approved edits to instructions, skills, scripts and memory | `claude-md-management:revise-claude-md`, which only edits CLAUDE.md |

## Repository structure

- `skills/`: portable skills, standard frontmatter only
- `claude/`: Claude Code-only pieces (wrapper skills, hooks)
- `instructions/global.md`: global rules shared by every tool
- `AGENTS.md`: how to maintain this repo and write skills

## Licence

[MIT](LICENSE)
