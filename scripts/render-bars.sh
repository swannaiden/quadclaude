#!/bin/bash
# Render progress bars for tmux status bar
# Usage: render-bars.sh <window_index>
# Output: Ctx ████████░░░░ 78%  5h ██░░░░░░░░ 17%(~25%)  7d ████░░░░░░ 35%

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh" 2>/dev/null

WIN="${1:-0}"

# Read context % for the specified window
CTX=$(cat "${CLAUDE_WS_TMP}/claude_context_$WIN" 2>/dev/null || echo "0")

# Read usage quotas from cached file
if [ -f "${CLAUDE_WS_TMP}/claude_usage.json" ]; then
  FIVE_H=$(jq -r '.five_hour.utilization // 0' "${CLAUDE_WS_TMP}/claude_usage.json" 2>/dev/null)
  SEVEN_D=$(jq -r '.seven_day.utilization // 0' "${CLAUDE_WS_TMP}/claude_usage.json" 2>/dev/null)
  FIVE_RESET=$(jq -r '.five_hour.resets_at // empty' "${CLAUDE_WS_TMP}/claude_usage.json" 2>/dev/null)
  SEVEN_RESET=$(jq -r '.seven_day.resets_at // empty' "${CLAUDE_WS_TMP}/claude_usage.json" 2>/dev/null)
else
  FIVE_H="0"
  SEVEN_D="0"
  FIVE_RESET=""
  SEVEN_RESET=""
fi

# Round to integers
CTX=$(printf "%.0f" "$CTX" 2>/dev/null || echo "0")
FIVE_H=$(printf "%.0f" "$FIVE_H" 2>/dev/null || echo "0")
SEVEN_D=$(printf "%.0f" "$SEVEN_D" 2>/dev/null || echo "0")

# Project usage to end of window based on current rate
# projected = utilization * (window_seconds / elapsed_seconds)
parse_iso_date() {
  # Try GNU date first, then macOS-compatible python3
  date -d "$1" +%s 2>/dev/null && return
  python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$1').timestamp()))" 2>/dev/null
}

project_usage() {
  local util=$1
  local reset_at=$2
  local window_secs=$3
  if [ -z "$reset_at" ] || [ "$util" -eq 0 ]; then
    echo "0"
    return
  fi
  local now=$(date +%s)
  local reset_epoch=$(parse_iso_date "$reset_at")
  if [ -z "$reset_epoch" ]; then
    echo "0"
    return
  fi
  local remaining=$((reset_epoch - now))
  if [ "$remaining" -le 0 ]; then
    echo "$util"
    return
  fi
  local elapsed=$((window_secs - remaining))
  if [ "$elapsed" -le 0 ]; then
    echo "$util"
    return
  fi
  local projected=$((util * window_secs / elapsed))
  if [ "$projected" -gt 100 ]; then projected=100; fi
  echo "$projected"
}

FIVE_PROJ=$(project_usage "$FIVE_H" "$FIVE_RESET" 18000)    # 5h = 18000s
SEVEN_PROJ=$(project_usage "$SEVEN_D" "$SEVEN_RESET" 604800) # 7d = 604800s

# Generate a bar: percentage -> filled/empty blocks
# If projected is given, show projected portion with proj character
make_bar() {
  local pct=$1
  local proj=${2:-0}
  local step=$((100 / CLAUDE_WS_BAR_WIDTH))
  local filled=$((pct / step))
  local proj_filled=$((proj / step))
  if [ "$proj_filled" -gt "$CLAUDE_WS_BAR_WIDTH" ]; then proj_filled=$CLAUDE_WS_BAR_WIDTH; fi
  local extra=$((proj_filled - filled))
  if [ "$extra" -lt 0 ]; then extra=0; fi
  local empty=$((CLAUDE_WS_BAR_WIDTH - filled - extra))
  if [ "$empty" -lt 0 ]; then empty=0; fi
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="$CLAUDE_WS_BAR_FILL"; done
  for ((i=0; i<extra; i++)); do bar+="$CLAUDE_WS_BAR_PROJ"; done
  for ((i=0; i<empty; i++)); do bar+="$CLAUDE_WS_BAR_EMPTY"; done
  echo "$bar"
}

# Pick color based on percentage thresholds
pick_color() {
  local pct=$1
  if [ "$pct" -gt "$CLAUDE_WS_BAR_THRESHOLD_HIGH" ]; then
    echo "$CLAUDE_WS_BAR_COLOR_HIGH"
  elif [ "$pct" -gt "$CLAUDE_WS_BAR_THRESHOLD_MED" ]; then
    echo "$CLAUDE_WS_BAR_COLOR_MED"
  else
    echo "$CLAUDE_WS_BAR_COLOR_LOW"
  fi
}

CTX_BAR=$(make_bar "$CTX")
CTX_COLOR=$(pick_color "$CTX")
FIVE_BAR=$(make_bar "$FIVE_H" "$FIVE_PROJ")
FIVE_COLOR=$(pick_color "$FIVE_H")
SEVEN_BAR=$(make_bar "$SEVEN_D" "$SEVEN_PROJ")
SEVEN_COLOR=$(pick_color "$SEVEN_D")

# Format with tmux color codes
# Ctx: just current usage
# 5h/7d: current% (~projected%)
printf "#[fg=%s]Ctx %s %3d%%#[default]  " "$CTX_COLOR" "$CTX_BAR" "$CTX"
if [ "$FIVE_PROJ" -gt 0 ] && [ "$FIVE_PROJ" -ne "$FIVE_H" ]; then
  printf "#[fg=%s]5h %s %3d%%(~%d%%)#[default]  " "$FIVE_COLOR" "$FIVE_BAR" "$FIVE_H" "$FIVE_PROJ"
else
  printf "#[fg=%s]5h %s %3d%%#[default]  " "$FIVE_COLOR" "$FIVE_BAR" "$FIVE_H"
fi
if [ "$SEVEN_PROJ" -gt 0 ] && [ "$SEVEN_PROJ" -ne "$SEVEN_D" ]; then
  printf "#[fg=%s]7d %s %3d%%(~%d%%)#[default]" "$SEVEN_COLOR" "$SEVEN_BAR" "$SEVEN_D" "$SEVEN_PROJ"
else
  printf "#[fg=%s]7d %s %3d%%#[default]" "$SEVEN_COLOR" "$SEVEN_BAR" "$SEVEN_D"
fi
