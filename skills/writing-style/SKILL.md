---
name: writing-style
description: Writing style for any prose a person will read, covering tone, spelling, punctuation, Markdown structure and commit, PR and issue text, plus a review mode that checks and fixes existing text. Use when writing or editing docs, READMEs, Markdown or Quarto files, commit messages, PR or issue descriptions, code comments, emails or updates, or when asked to proofread text or check it against the user's style.
---

# Writing style

Write **plain**: short sentences, common words and only what the reader needs.
The project's own style and the existing document come first.
Use these rules where there is no existing guidance, and for new documents.

## Tone

- Lead with the point, then give detail only where the reader needs it
- Cut filler ("in order to", "various different", "it should be noted that"), hedging and repetition
- Use the active voice and concrete words
- Explain why only when the reason isn't obvious
- Write to the reader as "you", and describe software by what it does

## Spelling

- Match the spelling already used in the document or project
- Use Australian English for new documents: `-ise` and `-our` (organise, colour), `licence` as a noun and `license` as a verb, `program` for software
- Keep code, API names and quoted text as they are
- Ask which variant to use when a project's existing text mixes Australian, UK and US spelling

## Punctuation

- Avoid semicolons: split into two sentences, or use a colon or a list
- Leave out the Oxford comma ("tests, docs and config"), unless it is needed to make a complicated list clear or the document already uses it
- Use straight quotes in Markdown and code

## Structure

- In Markdown and Quarto files, put each sentence on its own line, unless the file already wraps differently
- Use sentence case for headings ("Running checks")
- Use a list for steps, options or parallel items, and a paragraph for an argument or explanation
- Use a table only when items share two or more attributes
- Put commands, paths, identifiers and values in backticks, and multi-line code in fenced blocks with a language
- Use descriptive link text ("the [install guide](...)")
- Keep headings shallow: rarely deeper than three levels

## Commits, PRs and issues

- **Commits**: follow the repo's history and any template, including gitmoji or conventional prefixes where the repo uses them.
  Write a short imperative subject ("Add retry to the HTTP client"), and add a body only when the why isn't obvious from the diff.
- **PRs**: follow the repo's PR template if there is one.
  Otherwise give a one-paragraph summary of what changed and why, then a short list of notable changes and how it was tested.
- **Issues**: follow the repo's issue template if there is one.
  Otherwise state the problem, how to reproduce it, what you expected and what happened, in that order.

## Everything else

For a question these rules and the document don't settle (word choice, hyphenation, capitalisation, abbreviations, dates, numbers), follow the [ANU writing style guide](https://services.anu.edu.au/marketing-outreach/storytelling-writing/writing-style-guide), leaving out its ANU-specific terms.
For example, it writes dates day first with no comma ("12 May 2026"), spells out one to nine and uses numerals from 10.
Where it is silent, use the Australian Government Style Manual.

## Review mode

When asked to proofread, check or fix existing text:

1. Read the whole document and note its existing conventions (spelling, list punctuation, line wrapping), so fixes match them
2. Check every rule above, and the fallback guide where a rule is silent, and collect each problem with its line
3. For a short text, give the corrected version.
   For a file, apply the fixes when the user asked for them, otherwise list them grouped by rule.
4. Keep the meaning: change wording only where a rule requires it or the user asked for rewriting

Done when every rule has been checked against the whole text.
