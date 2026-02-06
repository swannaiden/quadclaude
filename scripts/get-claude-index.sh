#!/bin/bash
# Get the correct Claude index (0-N) regardless of mode
# Uses $TMUX_PANE to identify the calling pane (stable per-shell)
# Caches result per pane since the index never changes for a given shell

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  CACHE_FILE="${CLAUDE_WS_TMP}/claude_index_cache_${TMUX_PANE//[^a-zA-Z0-9]/_}"

  # Return cached value if available
  if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
  fi

  PANE_COUNT=$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_index}' 2>/dev/null | wc -l)

  if [ "$PANE_COUNT" -gt 1 ]; then
    INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#{@orig_win}' 2>/dev/null)
  else
    INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}' 2>/dev/null)
  fi

  if [ -n "$INDEX" ] && [ "$INDEX" -lt "$CLAUDE_WS_NUM_CLAUDE" ] 2>/dev/null; then
    echo "$INDEX" > "$CACHE_FILE"
    echo "$INDEX"
  fi
fi
