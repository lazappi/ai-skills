---
name: draft-github-issue
description: Draft a GitHub issue for the current repository or an upstream project, using the target repository's issue template, checking for duplicates and building a minimal reproduction, then showing the draft without posting it. Use when the user asks for the text of an issue, a summary they can use to open an issue, or to report a bug or feature request to another project.
compatibility: Uses the GitHub CLI (gh) to read templates and search issues.
---

# Draft a GitHub issue

Write an issue that a maintainer who has never seen this project can act on.
The deliverable is a draft, only post it when the user asks.

## 1. Find the target

Use the repository the user names, or the current one (`gh repo view --json nameWithOwner`).
For an upstream bug, confirm which project owns the code that fails before you choose.
Done when you know the target `owner/repo`.

## 2. Check for duplicates

```bash
gh issue list --repo <owner/repo> --state all --search "<key words from the error>"
```

When an open issue already covers the problem, show it and ask whether to draft a comment on it instead.
Done when the search has run with the error text and with a plain description.

## 3. Get the template

List the target's templates:

```bash
gh api repos/<owner/repo>/contents/.github/ISSUE_TEMPLATE --jq '.[].name'
```

Read the most relevant one with `gh api repos/<owner/repo>/contents/.github/ISSUE_TEMPLATE/<file> --jq .content | base64 -d`.
For a YAML issue form, write one section per field, using the field labels as headings.
When there is no template, use: summary, steps to reproduce, expected, actual, environment.
Done when every required field of the template has a section.

## 4. Gather the facts

- Versions of the tools and packages involved, from the commands that report them
- A minimal reproduction: the fewest steps and the smallest input that show the problem. Run once to confirm it still fails.
- The relevant part of the error output, trimmed to the lines that matter
- What you already ruled out

Replace private details (local paths, user names, client or project names, internal URLs and data) with generic placeholders.
Done when the reproduction fails as described.

## 5. Write and show

Keep it brief: a title that names the symptom, then the template sections.
Follow the `writing-style` skill when it is installed.
Show the draft in the reply, or write it to a file the user names.

Post it with `gh issue create --repo <owner/repo> --title <title> --body-file <file>` only after the user asks, and give them the issue URL.
