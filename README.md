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

## Repository structure

- `skills/`: portable skills, standard frontmatter only
- `claude/`: Claude Code-only pieces (wrapper skills, hooks)
- `instructions/global.md`: global rules shared by every tool
- `AGENTS.md`: how to maintain this repo and write skills

## Licence

[MIT](LICENSE)
