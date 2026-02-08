#!/bin/bash
# Polls Anthropic API for session/weekly usage quotas
# Writes result to $CLAUDE_WS_TMP/claude_usage.json
# Run in a background loop: fetch-usage.sh [interval_seconds]
#
# Authentication priority:
#   1. CLAUDE_OAUTH_TOKEN env var
#   2. .env file next to this script
#   3. macOS Keychain (Claude Code-credentials)
#   4. ~/.claude/.credentials.json

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

INTERVAL="${1:-$CLAUDE_WS_POLL_INTERVAL}"

get_token() {
  # 1. Check environment variable
  if [ -n "$CLAUDE_OAUTH_TOKEN" ]; then
    echo "$CLAUDE_OAUTH_TOKEN"
    return
  fi

  # 2. Try .env file next to this script
  if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    if [ -n "$CLAUDE_OAUTH_TOKEN" ]; then
      echo "$CLAUDE_OAUTH_TOKEN"
      return
    fi
  fi

  # 3. Try macOS Keychain
  if command -v security &>/dev/null; then
    local CREDS=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    if [ -n "$CREDS" ]; then
      local TOKEN=$(echo "$CREDS" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      if [ -n "$TOKEN" ]; then
        echo "$TOKEN"
        return
      fi
    fi
  fi

  # 4. Try credentials file (Linux)
  local CREDS_FILE="$HOME/.claude/.credentials.json"
  if [ -f "$CREDS_FILE" ]; then
    local TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
      echo "$TOKEN"
      return
    fi
  fi
}

fetch_once() {
  local TOKEN=$(get_token)
  if [ -z "$TOKEN" ]; then
    return 1
  fi

  local RESPONSE=$(curl -s --max-time 10 \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  # Validate response has expected fields
  if echo "$RESPONSE" | jq -e '.five_hour' >/dev/null 2>&1; then
    echo "$RESPONSE" > "${CLAUDE_WS_TMP}/claude_usage.json"
  fi
}

# If run with --once, fetch once and exit
if [ "$1" = "--once" ]; then
  fetch_once
  exit $?
fi

# Background loop
while true; do
  fetch_once
  sleep "$INTERVAL"
done
