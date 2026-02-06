#!/bin/bash
# Write Claude status to a file that tmux can read for dynamic coloring
# Called by hooks: UserPromptSubmit, PreToolUse, Stop
# Uses $TMUX_PANE to identify the calling pane (not the focused one)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  STATUS="${1:-idle}"

  # Use get-claude-index.sh which handles both modes via $TMUX_PANE
  INDEX=$("$SCRIPT_DIR/get-claude-index.sh")

  # Only write status for Claude windows/panes
  if [ -n "$INDEX" ]; then
    echo "$STATUS" > "${CLAUDE_WS_TMP}/claude_status_${INDEX}"
  fi
fi
