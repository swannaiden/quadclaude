#!/bin/bash
# QuadClaude - Configuration
# Edit these values to customize your workspace.
# All values have sensible defaults -- you only need to change what you want.

# --- Layout ---
CLAUDE_WS_NUM_CLAUDE="${CLAUDE_WS_NUM_CLAUDE:-4}"       # Number of Claude Code windows
CLAUDE_WS_NUM_BASH="${CLAUDE_WS_NUM_BASH:-3}"           # Number of bash utility windows
CLAUDE_WS_PREFIX="${CLAUDE_WS_PREFIX:-main}"             # Claude -r session name prefix (main_1, main_2, ...)

# --- Status Colors (tmux colour names or hex #rrggbb) ---
CLAUDE_WS_COLOR_THINKING="${CLAUDE_WS_COLOR_THINKING:-colour27}"    # Blue - waiting for AI response
CLAUDE_WS_COLOR_RUNNING="${CLAUDE_WS_COLOR_RUNNING:-colour178}"     # Yellow - tool execution
CLAUDE_WS_COLOR_IDLE="${CLAUDE_WS_COLOR_IDLE:-colour28}"            # Green - ready for input
CLAUDE_WS_COLOR_WAITING="${CLAUDE_WS_COLOR_WAITING:-colour196}"     # Red - needs attention

# --- Progress Bar Colors (thresholds) ---
CLAUDE_WS_BAR_COLOR_LOW="${CLAUDE_WS_BAR_COLOR_LOW:-colour33}"      # Blue - usage below medium threshold
CLAUDE_WS_BAR_COLOR_MED="${CLAUDE_WS_BAR_COLOR_MED:-colour178}"     # Yellow - usage between thresholds
CLAUDE_WS_BAR_COLOR_HIGH="${CLAUDE_WS_BAR_COLOR_HIGH:-colour196}"   # Red - usage above high threshold
CLAUDE_WS_BAR_THRESHOLD_MED="${CLAUDE_WS_BAR_THRESHOLD_MED:-60}"    # % to switch from low to med color
CLAUDE_WS_BAR_THRESHOLD_HIGH="${CLAUDE_WS_BAR_THRESHOLD_HIGH:-85}"  # % to switch from med to high color

# --- Progress Bar Characters ---
CLAUDE_WS_BAR_WIDTH="${CLAUDE_WS_BAR_WIDTH:-20}"        # Bar width in characters
CLAUDE_WS_BAR_FILL="${CLAUDE_WS_BAR_FILL:-█}"           # Filled block character
CLAUDE_WS_BAR_PROJ="${CLAUDE_WS_BAR_PROJ:-▓}"           # Projected usage character
CLAUDE_WS_BAR_EMPTY="${CLAUDE_WS_BAR_EMPTY:-░}"         # Empty block character

# --- Status Bar Appearance ---
CLAUDE_WS_STATUS_BG="${CLAUDE_WS_STATUS_BG:-colour235}"             # Status bar background
CLAUDE_WS_STATUS_FG="${CLAUDE_WS_STATUS_FG:-colour250}"             # Status bar foreground
CLAUDE_WS_BASH_BAR_BG="${CLAUDE_WS_BASH_BAR_BG:-colour166}"        # Bash windows bar background
CLAUDE_WS_PANE_BORDER="${CLAUDE_WS_PANE_BORDER:-colour240}"        # Inactive pane border (grid mode)
CLAUDE_WS_PANE_ACTIVE="${CLAUDE_WS_PANE_ACTIVE:-colour33}"         # Active pane border (grid mode)

# --- Timing ---
CLAUDE_WS_POLL_INTERVAL="${CLAUDE_WS_POLL_INTERVAL:-60}"            # Usage API poll interval (seconds)
CLAUDE_WS_THROTTLE_SECS="${CLAUDE_WS_THROTTLE_SECS:-5}"            # Statusline expensive-work throttle
CLAUDE_WS_TITLE_MAX="${CLAUDE_WS_TITLE_MAX:-60}"                    # Max chars for window titles

# --- Paths ---
CLAUDE_WS_TMP="${CLAUDE_WS_TMP:-/tmp}"                              # IPC file directory
