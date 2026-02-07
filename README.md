# 🖥️ QuadClaude

> Run four Claude Code sessions in one tmux workspace with live status monitoring

![Normal mode with status bar](images/normal-mode.png) 

## ✨ Features

### Multi-Session Workspace
Launch multiple Claude Code windows and bash utility windows in a single tmux session. Click any window in the status bar to switch to it.

### Live Status Colors
Each window lights up based on what Claude is doing:

| Color | State | Meaning |
|-------|-------|---------|
| 🔵 Blue | Thinking | Processing your prompt |
| 🟡 Yellow | Running | Executing a tool |
| 🟢 Green | Idle | Ready for input |
| 🔴 Red | Waiting | Needs your attention |

### Real-Time Progress Bars
Context window usage, 5-hour, and 7-day API quota bars with projected usage indicators:
```
Ctx ████████████░░░░░░░░  60%   5h ███▓▓▓░░░░░░░░░░░░░░  17%(~43%)   7d █▓▓▓▓▓▓▓▓▓░░░░░░░░░░   6%(~52%)
    ^^^^^^^^^^^^                      ^^^                                ^^^^^^^^^
    current usage                     projected                          projected
```

### Grid Mode
Toggle between tabbed windows and a tiled pane layout with **`Ctrl+b g`**. Pane borders show each session's current task.

![Grid mode](images/grid-mode.png)

### Auto-Updating Titles
Window names update automatically from in-progress task descriptions. See what each Claude is working on at a glance -- no manual updates needed.

### Usage Monitoring
Background polling of the Anthropic API for quota data. Authenticates via your existing Claude Code OAuth credentials -- zero setup required.

---

## 📋 Requirements

| Tool | Version | Notes |
|------|---------|-------|
| tmux | 3.2+ | Multi-line status bar support |
| Claude Code | latest | The `claude` CLI |
| jq | any | JSON parsing |
| curl | any | API polling |
| bash | 4+ | Script execution |
| GNU date | any | macOS: `brew install coreutils` |

---

## 🚀 Quick Start

### 1. Clone and install

```bash
git clone https://github.com/swannaiden/quadclaude.git
cd quadclaude
./install.sh /path/to/your/project
```

### 2. Launch

```bash
.claude/scripts/launch-claude-workspace.sh
```

Or with a custom session name:

```bash
.claude/scripts/launch-claude-workspace.sh my-session /path/to/project
```

### 3. (Optional) API usage bars

Works automatically if you're logged into Claude Code. The OAuth token is read from `~/.claude/.credentials.json`.

You can also set `CLAUDE_OAUTH_TOKEN` in your environment or in `.claude/scripts/.env`.

---

## 🎛️ Customization

Everything is in one file. After installing, edit `.claude/config.sh`:

### Layout
```bash
CLAUDE_WS_NUM_CLAUDE=4              # 🖥️  Number of Claude windows
CLAUDE_WS_NUM_BASH=3                # 💻 Number of bash windows
CLAUDE_WS_PREFIX="main"             # 🏷️  Session name prefix (main_1, main_2, ...)
```

### Status Colors
```bash
CLAUDE_WS_COLOR_THINKING="colour27"   # 🔵 Blue
CLAUDE_WS_COLOR_RUNNING="colour178"   # 🟡 Yellow
CLAUDE_WS_COLOR_IDLE="colour28"       # 🟢 Green
CLAUDE_WS_COLOR_WAITING="colour196"   # 🔴 Red
```

### Progress Bars
```bash
CLAUDE_WS_BAR_COLOR_LOW="colour33"    # Usage < 60%
CLAUDE_WS_BAR_COLOR_MED="colour178"   # Usage 60-85%
CLAUDE_WS_BAR_COLOR_HIGH="colour196"  # Usage > 85%
CLAUDE_WS_BAR_FILL="█"               # Filled character
CLAUDE_WS_BAR_PROJ="▓"               # Projected usage
CLAUDE_WS_BAR_EMPTY="░"              # Empty character
CLAUDE_WS_BAR_WIDTH=20               # Bar width
```

### Appearance
```bash
CLAUDE_WS_STATUS_BG="colour235"       # Status bar background
CLAUDE_WS_STATUS_FG="colour250"       # Status bar text
CLAUDE_WS_BASH_BAR_BG="colour166"     # Bash tab bar
CLAUDE_WS_PANE_BORDER="colour240"     # Grid mode borders
CLAUDE_WS_PANE_ACTIVE="colour33"      # Active pane border
```

### Timing
```bash
CLAUDE_WS_POLL_INTERVAL=60            # ⏱️  API poll interval (seconds)
CLAUDE_WS_THROTTLE_SECS=5             # Statusline update throttle
CLAUDE_WS_TITLE_MAX=60                # Max title characters
```

All values can also be set as environment variables before launching.

---

## 📦 What Gets Installed

```
your-project/
└── .claude/
    ├── config.sh                       # 🎨 Theme and settings
    ├── scripts/
    │   ├── launch-claude-workspace.sh  # 🚀 Entry point
    │   ├── set-claude-status.sh        # 🪝 Hook: status writer
    │   ├── statusline.sh              # 📊 Context/title updater
    │   ├── get-status-color.sh        # 🎨 Status -> color
    │   ├── fetch-usage.sh             # 📡 API quota poller
    │   ├── render-bars.sh             # 📊 Progress bar renderer
    │   ├── toggle-layout.sh           # 🔲 Grid mode toggle
    │   ├── get-claude-index.sh        # 🔢 Pane -> session mapper
    │   ├── get-pane-title.sh          # 🏷️  Title lookup
    │   └── .env.example               # 🔑 OAuth token template
    ├── skills/
    │   └── update-status/
    │       └── SKILL.md               # ✏️  Manual title update
    └── settings.local.json            # ⚙️  Hooks + statusLine config
```

---

## 🔧 How It Works

The workspace uses **file-based IPC** via `/tmp/` for communication between Claude Code, tmux, and the background poller. No sockets, no daemons, no lock files -- just simple files that tmux reads every 3 seconds.

### Data Flow

```
Claude Code hooks                    statusline.sh (~300ms)
  │                                    │
  ├─ UserPromptSubmit ──► thinking     ├─ context % ──► /tmp/claude_context_N
  ├─ PreToolUse ────────► running      └─ task title ─► /tmp/claude_title_N
  └─ Stop ──────────────► idle
  │                                  fetch-usage.sh (background, every 60s)
  └──► /tmp/claude_status_N            └─ API quota ──► /tmp/claude_usage.json

tmux status bar (every 3s)
  ├─ get-status-color.sh ◄── /tmp/claude_status_N    ──► window colors
  └─ render-bars.sh ◄─────── /tmp/claude_context_N   ──► progress bars
                              /tmp/claude_usage.json
```

---

## ⌨️ Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+b g` | 🔲 Toggle grid mode |
| `Ctrl+b 0-3` | Switch to Claude window |
| `Ctrl+b 4-6` | Switch to bash window |
| Click status bar | Switch to clicked window |

---

## 🖥️ Compatibility

- ✅ Tested with tmux 3.4 on Linux
- ✅ Requires tmux 3.2+ for multi-line status bar
- ⚠️ macOS: `date -d` requires GNU coreutils (`brew install coreutils`)
- ✅ Handles both GNU and BSD `stat` for file modification times

---

## 📄 License

MIT
