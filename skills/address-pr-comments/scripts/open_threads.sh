#!/usr/bin/env bash
# Print the unresolved review threads on a GitHub pull request.
# Usage: open_threads.sh <pr-number> [owner/repo]
set -o errexit -o nounset -o pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <pr-number> [owner/repo]" >&2
  exit 2
fi

pr="$1"
repo="${2:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
owner="${repo%%/*}"
name="${repo#*/}"

# shellcheck disable=SC2016
query='query($owner: String!, $name: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 50) {
            nodes { author { login } body url }
          }
        }
      }
    }
  }
}'

gh api graphql --paginate \
  -f query="$query" -F owner="$owner" -F name="$name" -F pr="$pr" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | "== \(.path):\(.line // .originalLine // "?")\(if .isOutdated then " (outdated)" else "" end)\n"
      + ([.comments.nodes[] | "-- \(.author.login // "ghost"): \(.body)\n   \(.url)"] | join("\n"))
      + "\n"'
