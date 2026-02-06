#!/bin/bash
# Toggle between normal (windows) and grid (panes) layout
# Normal: N separate windows, clickable status bar
# Grid: Windows 0..N-1 joined as panes in tiled layout

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

SESSION="${1:-claude-workspace}"

# Check if in grid mode (window 0 has multiple panes)
PANE_COUNT=$(tmux list-panes -t "$SESSION:0" 2>/dev/null | wc -l)

if [ "$PANE_COUNT" -gt 1 ]; then
  # Currently in grid mode -> exit to normal (break panes back to windows)

  # Get pane info with @orig_win mapping, sorted by @orig_win
  # This ensures panes are broken in order so they become correct windows
  PANES=$(tmux list-panes -t "$SESSION:0" -F '#{pane_id}:#{@orig_win}' | grep -v ':0$' | sort -t: -k2 -n)

  for PANE_INFO in $PANES; do
    PANE_ID=$(echo "$PANE_INFO" | cut -d: -f1)
    ORIG_WIN=$(echo "$PANE_INFO" | cut -d: -f2)
    # Get title from shared file
    TITLE=$(cat "${CLAUDE_WS_TMP}/claude_title_$ORIG_WIN" 2>/dev/null || echo "Claude $((ORIG_WIN + 1))")
    tmux break-pane -d -s "$PANE_ID" -n "$TITLE"
  done

  # Rename window 0 from its title file
  TITLE_0=$(cat "${CLAUDE_WS_TMP}/claude_title_0" 2>/dev/null || echo "Claude 1")
  tmux rename-window -t "$SESSION:0" "$TITLE_0"

  # Show status bar in normal mode
  tmux set-option -t "$SESSION" status $((CLAUDE_WS_NUM_CLAUDE + 1))

else
  # Currently in normal mode -> enter grid (join windows as panes)

  # Only initialize title files if they don't exist yet
  # Title files are the source of truth -- don't overwrite from window names
  for i in $(seq 0 $((CLAUDE_WS_NUM_CLAUDE - 1))); do
    if [ ! -f "${CLAUDE_WS_TMP}/claude_title_$i" ]; then
      NAME=$(tmux display-message -t "$SESSION:$i" -p '#{window_name}' 2>/dev/null)
      echo "$NAME" > "${CLAUDE_WS_TMP}/claude_title_$i"
    fi
  done

  # Save pane IDs before joining
  declare -a PIDS
  for i in $(seq 0 $((CLAUDE_WS_NUM_CLAUDE - 1))); do
    PIDS[$i]=$(tmux display-message -t "$SESSION:$i" -p '#{pane_id}')
  done

  # Join windows into window 0 as panes (reverse order to keep indices valid)
  for i in $(seq $((CLAUDE_WS_NUM_CLAUDE - 1)) -1 1); do
    tmux join-pane -d -s "$SESSION:$i" -t "$SESSION:0"
  done

  # tiled layout automatically arranges panes as grid
  tmux select-layout -t "$SESSION:0" tiled

  # Set @orig_win on each pane using saved pane_ids
  for i in $(seq 0 $((CLAUDE_WS_NUM_CLAUDE - 1))); do
    tmux set-option -p -t "${PIDS[$i]}" @orig_win "$i"
  done

  # Enable pane border status - use helper script to get correct title
  tmux set-option -g pane-border-status top
  tmux set-option -g pane-border-format " #($SCRIPT_DIR/get-pane-title.sh #{pane_id}) "
  tmux set-option -t "$SESSION" pane-border-style "fg=$CLAUDE_WS_PANE_BORDER"
  tmux set-option -t "$SESSION" pane-active-border-style "fg=$CLAUDE_WS_PANE_ACTIVE,bold"

  # Hide status bar in grid mode (pane borders show status)
  tmux set-option -t "$SESSION" status off

fi
