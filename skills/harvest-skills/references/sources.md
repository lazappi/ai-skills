# Where to find instructions and usage

Tools move these files between releases, so check each path exists and peek at a few lines before relying on its format.
Skip a tool that isn't installed.

## Instructions

| Tool | Global | Project |
| - | - | - |
| Claude Code | `~/.claude/CLAUDE.md` and the files it `@` imports | `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` |
| Codex | `~/.codex/AGENTS.md` | `AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` | `GEMINI.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `AGENTS.md` |
| Any | | `CONTRIBUTING.md`, `.github/copilot-instructions.md`, `.cursor/rules/` |

Find project files under the code folders the user names, for example:

```bash
find <code-folder> -maxdepth 4 \( -name AGENTS.md -o -name CLAUDE.md -o -name GEMINI.md \) -not -path '*/node_modules/*'
```

## Skills and commands already in use

- Personal skills: `~/.claude/skills/`, `~/.agents/skills/`, `~/.codex/skills/`, `~/.gemini/skills/`
- Project skills and commands: `.claude/skills/`, `.claude/commands/`, `.agents/skills/` in each project
- Claude Code plugins: `claude plugin list`, with each plugin's skills under `~/.claude/plugins/cache/`
- Project subagents: `.claude/agents/`

## Usage history

- **Claude Code prompts**: `~/.claude/history.jsonl`, one JSON object per prompt with `display` (the prompt) and `project` (its folder).
  Run `scripts/prompt_patterns.py` on it.
- **Claude Code transcripts**: `~/.claude/projects/<folder>/*.jsonl`, one file per session.
  These are large: search them for specific words (corrections such as "no,", "instead", "again") rather than reading them whole.
- **Codex**: `~/.codex/history.jsonl` and session logs in `~/.codex/sessions/`
- **Gemini CLI**: checkpoints and logs under `~/.gemini/tmp/`
- **OpenCode**: session data under `~/.local/share/opencode/`

For a JSONL file in another format, check which fields hold the prompt and project.
`prompt_patterns.py` reads `display`, `prompt`, `text` or `content`, and `project`, `cwd` or `directory`.
