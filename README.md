# ai-skills

My personal skills and global instructions for AI coding agents.
Skills follow the [Agent Skills](https://agentskills.io) open standard, so the same files work in Claude Code, Codex, Gemini CLI, OpenCode and claude.ai.
In Claude Code the repo installs as the `lazappi` plugin.

## Install

### Claude Code

```bash
claude plugin marketplace add lazappi/ai-skills
claude plugin install lazappi@lazappi
```

### Every tool from a clone

Clone the repo, then link the skills and global instructions into each tool and install the Claude Code plugins listed in `plugins.txt`:

```bash
git clone https://github.com/lazappi/ai-skills.git
cd ai-skills
scripts/install.sh install --remote
```

This needs [jq](https://jqlang.org) for the Claude Code steps, and skips them if `claude` isn't installed.
`--remote` adds the marketplace from GitHub and leaves the repo's git hooks off.
On a machine where you edit the skills, run `just install` instead, so Claude Code reads the local checkout and commits run the pre-commit checks.
Add `--dry-run` to see what would change.

| Tool | Skills | Global instructions |
| - | - | - |
| Claude Code | `lazappi` plugin | `~/.claude/CLAUDE.md`, managed separately |
| Codex | `~/.agents/skills/` | `~/.codex/AGENTS.md` (link) |
| Gemini CLI | `~/.agents/skills/` | `~/.gemini/GEMINI.md` (import line) |
| OpenCode | `~/.agents/skills/` | `~/.config/opencode/AGENTS.md` (link) |

Existing files are never overwritten: the script reports them and exits non-zero.
`just update` pulls the repo, installs again and updates the Claude Code plugins (restart Claude Code afterwards).
`just uninstall` removes only what the install created, including the git hooks setting.

### Other tools

Copy a folder from `skills/` into the tool's skills folder, or use [`npx skills`](https://github.com/vercel-labs/skills):

```bash
npx skills add lazappi/ai-skills -g
```

### claude.ai

`just package` writes one zip per skill to `dist/`.
Upload them in claude.ai's skill settings.
Skills uploaded there also sync to Claude Code sessions signed in to the same account.

### Caveats

- In Cowork sessions, `@` imports in `~/.claude/CLAUDE.md` that point outside the working folder are skipped, so the global instructions don't load there
- Claude-only wrapper skills in `claude/skills/` are installed only by the plugin

## Skills

| Skill | Use it for | Adds over |
| - | - | - |
| `phase-review` | Reviewing a finished phase against its plan into a severity-ranked review file, then fixing from it | `code-review`, which reviews diffs rather than a phase against its plan and writes no file |
| `r-package-dev` | Developing R packages with formatting, lint, roxygen2, testthat, NEWS.md, version and Bioconductor conventions | No existing skill covers R package conventions |
| `repo-tidy` | Auditing a whole repo into a prioritised checklist of fixes before changing anything | `simplify`, which only edits recently changed code |
| `session-retrospective` | Turning a session's lessons into approved edits to instructions, skills, scripts and memory | `claude-md-management:revise-claude-md`, which only edits CLAUDE.md |
| `writing-style` | Writing and proofreading prose, Markdown, commits, PRs and issues in a plain style with Australian spelling by default | No existing skill covers a personal writing style |

## Repository structure

- `skills/`: portable skills, standard frontmatter only
- `claude/skills/`: Claude Code-only wrapper skills
- `instructions/global.md`: global rules shared by every tool
- `plugins.txt`: third-party Claude Code plugins that the install script adds
- `evals/`: `claude plugin eval` cases that check each skill triggers, run with `just eval <skill>`
- `scripts/` and `tests/`: install, validation and packaging tooling, run with `just validate` and `just test`
- `AGENTS.md`: how to maintain this repo and write skills

## Licence

[MIT](LICENSE)
