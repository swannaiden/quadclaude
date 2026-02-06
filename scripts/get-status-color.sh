#!/bin/bash
# Returns tmux color code based on Claude status file
# Called by tmux status-format to determine window background color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

WINDOW="${1:-0}"
STATUS=$(cat "${CLAUDE_WS_TMP}/claude_status_${WINDOW}" 2>/dev/null || echo "idle")

case "$STATUS" in
  thinking) echo "$CLAUDE_WS_COLOR_THINKING" ;;
  running)  echo "$CLAUDE_WS_COLOR_RUNNING" ;;
  waiting)  echo "$CLAUDE_WS_COLOR_WAITING" ;;
  *)        echo "$CLAUDE_WS_COLOR_IDLE" ;;
esac
