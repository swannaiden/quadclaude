#!/bin/bash
# Get the title for a specific pane by its pane_id
# Usage: get-pane-title.sh %<pane_id>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

PANE_ID="$1"

if [ -z "$PANE_ID" ]; then
  echo "?"
  exit 0
fi

# Get @orig_win for this pane
ORIG_WIN=$(tmux display-message -t "$PANE_ID" -p '#{@orig_win}' 2>/dev/null)

if [ -n "$ORIG_WIN" ]; then
  # Read from the correct title file
  TITLE=$(cat "${CLAUDE_WS_TMP}/claude_title_$ORIG_WIN" 2>/dev/null)
  if [ -n "$TITLE" ]; then
    echo "$TITLE"
  else
    echo "Claude $((ORIG_WIN + 1))"
  fi
else
  # Fallback: try pane_index
  PANE_IDX=$(tmux display-message -t "$PANE_ID" -p '#{pane_index}' 2>/dev/null)
  echo "Claude $((PANE_IDX + 1))"
fi
