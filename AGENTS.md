# Agent instructions for ai-skills

This repo holds general, reusable agent skills and global instructions.
It is public, so everything here must be safe to publish.
Project-specific instructions belong in their own projects, not here.

## Layout

- `skills/<name>/SKILL.md`: portable skills, installed into every tool
- `claude/skills/<name>/SKILL.md`: Claude Code-only wrapper skills
- `instructions/global.md`: global rules, linked into each tool's global instructions file
- `evals/<skill>-<case>/`: `claude plugin eval` cases, tagged with the skill name
- `plugins.txt`: third-party Claude Code plugins that `just install` installs
- `.claude-plugin/`: the repo root is both the `lazappi` marketplace and the `lazappi` plugin
- `scripts/` and `tests/`: install, validation and packaging tooling

## Rules

- Never commit, push or rewrite history: the maintainer makes every commit
- No personal data: no emails, home paths with usernames, tokens or career facts, including in tests (build sample strings at runtime)
- Personalised skills read personal data from `~/.config/ai-skills/<skill>/` and ask for it when it is missing
- `instructions/global.md` has no `@` imports, because Codex and OpenCode don't expand them
- Shell scripts support macOS and Linux, run on bash 3.2 (no `mapfile`, no associative arrays) and quote every path
- Pre-commit checks stay fast and never call an agent
- Commit messages use gitmoji.
  The gitmoji hook skips commits made without a terminal, so any agent allowed to commit writes the emoji itself.
- Markdown uses one sentence per line, no semicolons and no Oxford comma

## Writing skills

Build a skill only when it adds something over existing skills and plugins, and say what in the README "Adds over" column.

- Frontmatter in `skills/` uses only the spec fields: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
  claude.ai rejects any other field.
- `name` is lowercase letters, digits and single hyphens, at most 64 characters, and matches the folder name
- Write the `description` first.
  It says what the skill does and when to use it, with the words a user would actually type, in at most 1024 characters.
- Write the body as direct instructions to the agent, not as documentation about the skill
- Keep `SKILL.md` under 500 lines.
  Move detail into `references/` files one level deep and say when to read each one.
- Put deterministic steps in `scripts/` instead of describing them in prose
- Prefer short examples over long explanations
- Leave out facts that will go stale, such as versions and dates
- A Claude-only wrapper in `claude/skills/` adds Claude frontmatter (for example `disable-model-invocation`) and points to the portable skill.
  It never reuses the portable skill's name.
- Draft new skills with `skill-creator` and check them with `mattpocock-skills:writing-for-agents`
- Add `claude plugin eval` cases (at least 2 should-fire and 1 should-not-fire) before tuning a description

## Tasks

Run tasks with [just](https://just.systems).
The `justfile` lists every recipe, and `just --list` shows them.
