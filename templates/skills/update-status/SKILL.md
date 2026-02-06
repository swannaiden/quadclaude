---
name: update-status
description: Update the tmux window name with a summary of the current task
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash(*)
---

# Update Status

Update the tmux window name with a detailed summary of the current task.

## Instructions

When this skill is invoked:

1. Generate a **descriptive summary** (up to 60 characters) of what you are currently working on. Include relevant context such as:
   - The specific task or action
   - Model or project name if relevant
   - Key details (file names, feature names, etc.)

2. Run the following Bash command to update the status, replacing `<SUMMARY>` with your summary:

```bash
if [ -n "$TMUX" ]; then
  INDEX=$(__SCRIPT_DIR__/get-claude-index.sh)
  if [ -n "$INDEX" ]; then
    echo "<SUMMARY>" > ${CLAUDE_WS_TMP:-/tmp}/claude_title_$INDEX
    tmux rename-window -t "$TMUX_PANE" "<SUMMARY>"
  fi
fi
```

## Examples of good summaries

- "Implementing user authentication flow"
- "Debugging API rate limiter"
- "Refactoring database migration scripts"
- "Writing unit tests for payment module"
- "Reviewing PR #142 security changes"
- "Planning caching layer architecture"

The full line is available for the description (up to ~60 chars visible).
