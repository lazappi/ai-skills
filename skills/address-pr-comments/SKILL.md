---
name: address-pr-comments
description: Address PR comments by collecting the open review comments on a GitHub pull request, from people and bots such as Copilot, plus failing checks, then fixing them one at a time with the user choosing the order and drafting a reply for each. Use when the user asks to check, list, work through or fix the comments or review on a PR, or to respond to a Copilot review.
compatibility: Requires the GitHub CLI (gh), signed in.
---

# Address PR comments

Work through the open review comments on a pull request as a queue the user controls.
Fix the code, draft replies, and leave posting and commits to the user.

## 1. Find the PR

Use the PR the user names, or the PR for the current branch:

```bash
gh pr view --json number,url,headRefName,baseRefName
```

Check that the PR's head branch is checked out, and ask before you switch branches.
Done when you know the PR number and the code you are on matches its head.

## 2. Collect the feedback

Run the bundled script for the unresolved review threads:

```bash
bash scripts/open_threads.sh <pr-number>
```

It prints one block per open thread with its author, file, line, outdated flag and comments.
Also collect:

- Review summaries and conversation comments: `gh pr view <pr-number> --comments`
- Failing checks: `gh pr checks <pr-number>`, then the failed job's log with `gh run view <run-id> --log-failed`

Done when every open thread, review summary and failing check is on your list.

## 3. List and ask

Group comments that ask for the same change.
Show a table, most important first:

| # | From | Where | Ask | Proposal |
| - | - | - | - | - |
| 1 | reviewer | `R/read.R:42` | Handle empty input | Fix: return early with a warning |
| 2 | Copilot | `README.md:10` | Typo | Fix |
| 3 | Copilot | `R/write.R:7` | Use `vapply` | Decline: input is always length 1 |

The proposal is fix, reply only or decline, with a reason for a decline.
Check bot comments against the code before you propose a fix, because they are often wrong.
Mark outdated threads and say whether the current code already answers them.

Then ask which items to do and in what order.
Done when the user has chosen.

## 4. Work the queue

For each chosen item, one at a time:

1. Make the change and add or update a test that covers it
2. Run the related tests and checks with the project's own commands
3. Draft a short reply that says what changed, or why you declined

Stop after each item when the user asked to go one at a time.
Done when every chosen item is fixed or declined with a drafted reply.

## 5. Report

List each item with its outcome, the files changed and the drafted reply, ready to paste.
Leave the changes uncommitted, the replies unposted and the threads unresolved unless the user asks.
