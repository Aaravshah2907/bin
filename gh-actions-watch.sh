#!/bin/bash
# ============================================================
# gh-actions-watch.sh
# Monitors the most recent GitHub Actions run across all repos
# and sends an alert only when a run FAILS.
# Run via cron: */5 * * * * ~/.local/bin/gh-actions-watch.sh
# Or call manually after a git push: git push && gh-actions-watch.sh
# ============================================================

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/.config/shell/functions.sh"

# Requires `gh` CLI to be installed and authenticated
if ! command -v gh &>/dev/null; then
  echo "gh CLI not found. Install with: brew install gh"
  exit 1
fi

CACHE_FILE="/tmp/gh_actions_last_run"

# Fetch the latest run across all watched repos
# Get the latest run from the current git repo if inside one
if git rev-parse --git-dir &>/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
else
  exit 0
fi

if [ -z "$REPO" ]; then
  exit 0
fi

# Get the latest run ID and its status/conclusion
RUN_JSON=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status,conclusion,name,displayTitle 2>/dev/null)
RUN_ID=$(echo "$RUN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['databaseId'])" 2>/dev/null)
CONCLUSION=$(echo "$RUN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['conclusion'] or '')" 2>/dev/null)
WF_NAME=$(echo "$RUN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['name'])" 2>/dev/null)
TITLE=$(echo "$RUN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['displayTitle'])" 2>/dev/null)

# Bail if no runs found
if [ -z "$RUN_ID" ]; then
  exit 0
fi

# Read last alerted run ID
LAST_RUN_ID=""
[ -f "$CACHE_FILE" ] && LAST_RUN_ID=$(cat "$CACHE_FILE")

# Only act on new, completed runs
if [ "$RUN_ID" == "$LAST_RUN_ID" ]; then
  exit 0
fi

echo "$RUN_ID" > "$CACHE_FILE"

case "$CONCLUSION" in
  "failure"|"timed_out"|"startup_failure")
    alert "❌ GitHub Actions FAILED on [$REPO] — Workflow: '$WF_NAME' | '$TITLE'. Check the logs!"
    ;;
  "success")
    # Silent on success — no spam. Comment below line in if you want success pings too.
    # alert "✅ GitHub Actions PASSED on [$REPO] — '$WF_NAME' succeeded."
    ;;
  "cancelled")
    alert "⚠️ GitHub Actions was CANCELLED on [$REPO] — Workflow: '$WF_NAME'."
    ;;
esac
