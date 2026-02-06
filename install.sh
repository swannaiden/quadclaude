#!/bin/bash
# Install QuadClaude into a project's .claude/ directory
#
# Usage:
#   install.sh [target_dir]
#   target_dir defaults to current directory

set -e

TARGET_DIR="${1:-.}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

CLAUDE_DIR="$TARGET_DIR/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SKILLS_DIR="$CLAUDE_DIR/skills"

echo "Installing claude-tmux-workspace into $TARGET_DIR"
echo ""

# --- Check prerequisites ---
MISSING=""

# Check tmux version
if command -v tmux >/dev/null 2>&1; then
  TMUX_VER=$(tmux -V | sed 's/[^0-9.]//g')
  MAJOR=$(echo "$TMUX_VER" | cut -d. -f1)
  MINOR=$(echo "$TMUX_VER" | cut -d. -f2)
  if [ "$MAJOR" -lt 3 ] || ([ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 2 ]); then
    echo "WARNING: tmux $TMUX_VER detected, but 3.2+ is required for multi-line status bar."
  fi
else
  MISSING="$MISSING tmux"
fi

command -v jq >/dev/null 2>&1 || MISSING="$MISSING jq"
command -v curl >/dev/null 2>&1 || MISSING="$MISSING curl"

if [ -n "$MISSING" ]; then
  echo "ERROR: Missing required tools:$MISSING"
  echo "Please install them and try again."
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "NOTE: 'claude' CLI not found. Install Claude Code before launching the workspace."
  echo ""
fi

# --- Create directories ---
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$SKILLS_DIR/update-status"

# --- Copy scripts ---
echo "Copying scripts..."
for script in launch-claude-workspace.sh set-claude-status.sh statusline.sh \
              get-status-color.sh fetch-usage.sh render-bars.sh \
              toggle-layout.sh get-claude-index.sh get-pane-title.sh; do
  cp "$REPO_DIR/scripts/$script" "$SCRIPTS_DIR/$script"
  chmod +x "$SCRIPTS_DIR/$script"
done

# --- Copy config ---
if [ -f "$CLAUDE_DIR/scripts/../config.sh" ] || [ -f "$CLAUDE_DIR/../config.sh" ]; then
  echo "config.sh already exists, skipping."
else
  # Install config.sh one level up from scripts (at .claude/ level or project root)
  cp "$REPO_DIR/config.sh" "$CLAUDE_DIR/config.sh"
  chmod +x "$CLAUDE_DIR/config.sh"
  echo "Created $CLAUDE_DIR/config.sh (edit to customize colors, layout, etc.)"
fi

# --- Copy .env template ---
if [ ! -f "$SCRIPTS_DIR/.env" ]; then
  cp "$REPO_DIR/templates/env.example" "$SCRIPTS_DIR/.env.example"
  echo "Created $SCRIPTS_DIR/.env.example"
fi

# --- Copy skill template ---
sed "s|__SCRIPT_DIR__|$SCRIPTS_DIR|g" "$REPO_DIR/templates/skills/update-status/SKILL.md" \
  > "$SKILLS_DIR/update-status/SKILL.md"
echo "Created update-status skill"

# --- Handle settings.local.json ---
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
  if grep -q "set-claude-status.sh" "$SETTINGS_FILE"; then
    echo "Hooks already configured in settings.local.json"
  else
    echo ""
    echo "=== MANUAL STEP REQUIRED ==="
    echo "Add the following to your $SETTINGS_FILE:"
    echo ""
    cat "$REPO_DIR/templates/settings-hooks.json"
    echo ""
    echo "(Automatic merging skipped to preserve your existing config)"
    echo "============================="
  fi
else
  cp "$REPO_DIR/templates/settings-hooks.json" "$SETTINGS_FILE"
  echo "Created $SETTINGS_FILE with hooks and statusLine config"
fi

echo ""
echo "Installation complete!"
echo ""
echo "To launch the workspace:"
echo "  $SCRIPTS_DIR/launch-claude-workspace.sh [session-name] [$TARGET_DIR]"
echo ""
echo "To customize colors, layout, and timing:"
echo "  Edit $CLAUDE_DIR/config.sh"
echo ""
echo "Optional: Copy .env.example to .env and add your OAuth token"
echo "for API usage monitoring in the status bar."
