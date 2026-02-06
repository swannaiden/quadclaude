#!/bin/bash
# Launch a tmux session with N Claude windows + M bash windows
# Windows are clickable via status bar, Ctrl+b g toggles to grid view
#
# Usage: launch-claude-workspace.sh [session_name] [working_dir]

SESSION_NAME="${1:-claude-workspace}"
WORKING_DIR="${2:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load config
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

NUM_CLAUDE="$CLAUDE_WS_NUM_CLAUDE"
NUM_BASH="$CLAUDE_WS_NUM_BASH"
PREFIX="$CLAUDE_WS_PREFIX"
TMP="$CLAUDE_WS_TMP"

# Initialize status, title, and context files for Claude windows
for i in $(seq 0 $((NUM_CLAUDE - 1))); do
  echo "idle" > "${TMP}/claude_status_$i"
  echo "Claude $((i + 1))" > "${TMP}/claude_title_$i"
  echo "0" > "${TMP}/claude_context_$i"
done
# Clear stale caches from previous sessions
rm -f "${TMP}"/claude_index_cache_* "${TMP}"/claude_statusline_ts_* "${TMP}"/claude_transcript_mtime_*

# Start usage quota poller in background
"$SCRIPT_DIR/fetch-usage.sh" "$CLAUDE_WS_POLL_INTERVAL" &
USAGE_POLLER_PID=$!

# Create new session with first Claude window
tmux new-session -d -s "$SESSION_NAME" -n "Claude 1" -c "$WORKING_DIR"

# Create additional Claude windows
for i in $(seq 2 $NUM_CLAUDE); do
  tmux new-window -t "$SESSION_NAME" -n "Claude $i" -c "$WORKING_DIR"
done

# Create bash windows
for i in $(seq 1 $NUM_BASH); do
  tmux new-window -t "$SESSION_NAME" -n "bash$i" -c "$WORKING_DIR"
done

# Apply custom styling
tmux set-option -t "$SESSION_NAME" mouse on
tmux set-option -t "$SESSION_NAME" allow-rename on
tmux set-option -t "$SESSION_NAME" status-interval 3
tmux set-option -t "$SESSION_NAME" status-position bottom

# Status lines: one per Claude window + one for bash/bars
tmux set-option -t "$SESSION_NAME" status $((NUM_CLAUDE + 1))
tmux set-option -t "$SESSION_NAME" status-style "bg=$CLAUDE_WS_STATUS_BG,fg=$CLAUDE_WS_STATUS_FG"

# Pane border config (for grid mode)
tmux set-option -t "$SESSION_NAME" pane-border-status top
tmux set-option -t "$SESSION_NAME" pane-border-style "fg=$CLAUDE_WS_PANE_BORDER"
tmux set-option -t "$SESSION_NAME" pane-active-border-style "fg=$CLAUDE_WS_PANE_ACTIVE,bold"
tmux set-option -t "$SESSION_NAME" pane-border-format ' #{pane_title} '

# Status format for each Claude window (clickable via range=window|N)
COLOR_SCRIPT="$SCRIPT_DIR/get-status-color.sh"
for i in $(seq 0 $((NUM_CLAUDE - 1))); do
  tmux set-option -t "$SESSION_NAME" status-format[$i] \
    "#[align=left range=window|$i bg=#($COLOR_SCRIPT $i) fg=colour255]#{?#{==:#{window_index},$i}, >> ,    } $i: #(cat ${TMP}/claude_title_$i 2>/dev/null | cut -c1-${CLAUDE_WS_TITLE_MAX}) #[norange default]"
done

# Bottom bar: bash window tabs + progress bars + clock
BARS_SCRIPT="$SCRIPT_DIR/render-bars.sh"
BASH_LINE="#[align=left bg=$CLAUDE_WS_BASH_BAR_BG fg=colour255] "
for i in $(seq 0 $((NUM_BASH - 1))); do
  WIN_IDX=$((NUM_CLAUDE + i))
  BASH_LINE+="#[range=window|${WIN_IDX}]bash$((i+1))#[norange]  "
done
BASH_LINE+="#[default]#[align=right bg=default]#($BARS_SCRIPT #{window_index})  #[fg=colour244]%H:%M "
tmux set-option -t "$SESSION_NAME" status-format[$NUM_CLAUDE] "$BASH_LINE"

# Add keybinding for grid toggle (Ctrl+b g)
tmux bind-key -T prefix g run-shell "$SCRIPT_DIR/toggle-layout.sh $SESSION_NAME"

# Go to first window
tmux select-window -t "$SESSION_NAME:0"

# Build config export string for Claude panes
CONFIG_EXPORTS="export CLAUDE_WS_TMP='$TMP' CLAUDE_WS_NUM_CLAUDE='$NUM_CLAUDE' CLAUDE_WS_THROTTLE_SECS='$CLAUDE_WS_THROTTLE_SECS' CLAUDE_WS_TITLE_MAX='$CLAUDE_WS_TITLE_MAX' CLAUDE_WS_BAR_WIDTH='$CLAUDE_WS_BAR_WIDTH'"

# Start Claude sessions in each window
for i in $(seq 0 $((NUM_CLAUDE - 1))); do
  tmux send-keys -t "$SESSION_NAME:$i" "$CONFIG_EXPORTS" Enter
  tmux send-keys -t "$SESSION_NAME:$i" "claude -r ${PREFIX}_$((i+1))" Enter
done

# Attach to session (kill usage poller when detached/session ends)
tmux attach-session -t "$SESSION_NAME"
kill "$USAGE_POLLER_PID" 2>/dev/null
