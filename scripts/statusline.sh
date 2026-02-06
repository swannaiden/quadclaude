#!/bin/bash
# Claude Code statusline script
# Receives JSON via stdin from Claude Code's statusline feature
# Writes context % and task title to files for tmux to read
#
# Called ~every 300ms per session. Expensive work (transcript parsing)
# is throttled. The cheap status line output is always returned immediately.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

input=$(cat)

# Always extract context % (cheap, just string parsing)
USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Output for Claude Code's own status line (always, this is the cheap part)
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
CTX_INT=$(printf "%.0f" "$USED")
echo "[$MODEL] Ctx: ${CTX_INT}%"

# Get window index (cheap, cached after first call)
INDEX=$("$SCRIPT_DIR/get-claude-index.sh")
if [ -z "$INDEX" ]; then
  exit 0
fi

# Always write context % (cheap single printf, keeps tmux bars in sync)
printf "%.0f" "$USED" > "${CLAUDE_WS_TMP}/claude_context_$INDEX"

# Throttle expensive work
THROTTLE_FILE="${CLAUDE_WS_TMP}/claude_statusline_ts_$INDEX"
NOW=$(date +%s)
LAST=$(cat "$THROTTLE_FILE" 2>/dev/null || echo "0")
ELAPSED=$((NOW - LAST))

if [ "$ELAPSED" -lt "$CLAUDE_WS_THROTTLE_SECS" ]; then
  exit 0
fi
echo "$NOW" > "$THROTTLE_FILE"

# -- Expensive work below (runs once every ~THROTTLE_SECS) --

# Auto-update task title from transcript
# Only re-parse if transcript file changed (check mtime)
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  MTIME_FILE="${CLAUDE_WS_TMP}/claude_transcript_mtime_$INDEX"
  CURRENT_MTIME=$(stat -c %Y "$TRANSCRIPT" 2>/dev/null || stat -f %m "$TRANSCRIPT" 2>/dev/null)
  LAST_MTIME=$(cat "$MTIME_FILE" 2>/dev/null)

  if [ "$CURRENT_MTIME" != "$LAST_MTIME" ]; then
    echo "$CURRENT_MTIME" > "$MTIME_FILE"

    TASK=$(jq -r '
      [.[] |
        select(.type == "tool_result" or .type == "tool_use") |
        select(.name == "TodoWrite" or .tool_name == "TodoWrite") |
        .content // .input // {} |
        if type == "string" then (try fromjson catch {}) else . end |
        .todos // [] | .[] |
        select(.status == "in_progress") |
        .activeForm // .content
      ] | last // empty
    ' "$TRANSCRIPT" 2>/dev/null)

    if [ -n "$TASK" ]; then
      echo "$TASK" | cut -c1-"$CLAUDE_WS_TITLE_MAX" > "${CLAUDE_WS_TMP}/claude_title_$INDEX"
      tmux rename-window -t "$TMUX_PANE" "$(cat "${CLAUDE_WS_TMP}/claude_title_$INDEX")" 2>/dev/null
    fi
  fi
fi
