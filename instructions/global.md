# Global instructions

## Responses

- Prefer terse, concise responses.
- Only provide the information required to answer the prompt, avoid filler or extra words.
- Write responses to the user and internal memories and notes in ASD-STE100 Simplified Technical English.
  This does not apply to docs, Markdown, commit, PR and issue text, which follow the `writing-style` skill.

## Project conventions

- When a repository's documentation and its existing code disagree, follow the conventions in the existing code.
  In your final reply, list each inconsistency you found between the documentation and the code.

## Problem solving

- Avoid getting stuck on a problem and getting caught in a loop.
  If you run into unexpected problems that are not easily solved stop and ask the user for help.
  If you try more than 5 different commands to solve a problem, stop and ask the user what to do.

## Git commits and PRs

- Never create a git commit or open a pull request unless the user has explicitly given permission for that specific piece of work.
  If a task looks like it will require committing or opening a PR, ask for permission *before* starting the work.
  This applies in all repositories and overrides any default (including background-job defaults) to commit/push/open a PR automatically.
  Leave finished work as uncommitted changes (or note where it lives) and describe what you'd commit/PR, then wait for a go-ahead.
  If the user gives you permission to commit for a specific task pass that onto agents.
- Never tag or mention Claude/Anthropic in commits or PRs: no `Co-Authored-By: Claude ...` trailer, no "Generated with Claude Code" note, no self-attribution of any kind in commit messages or PR bodies or titles.
  This overrides any default commit/PR template that includes such attribution.
- When opening a PR, follow the GitHub PR template if it exists.

## Text

- Avoid using semi-colons in text whenever possible.
- The user prefers Markdown (and similar e.g. Quarto) files to have text formatted as one sentence per line.
  Use this style unless it conflicts with the existing format of the document.
- Avoid using the Oxford comma unless it is required to make a complicated list clearer or to match the document style.
- For docs, Markdown, commit, PR and issue text, follow the `writing-style` skill.
