# Herd 🐑

**A macOS menu bar app that shows how many Claude Code agents are running and which ones need your attention.**

<p align="center">
  <code>🤖 3 | ⏳ 1</code>
</p>

Running multiple Claude Code agents across terminals? Herd sits in your menu bar and tells you at a glance:

- **How many agents** are currently running
- **Which ones are waiting** for your input
- **What they last said** — so you know what needs attention
- **One click** to jump to any agent's terminal

## How it works

Herd uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to track agent lifecycle events. Four lightweight bash scripts fire on `SessionStart`, `SessionEnd`, `Stop`, and `UserPromptSubmit`, sending JSON messages to a local Unix socket. The menu bar app listens on that socket and updates in real time.

```
Claude Code hooks  ──→  /tmp/herd.sock  ──→  Menu bar app
(bash + jq)              (Unix socket)        (Swift + SwiftUI)
```

No network calls. No API keys. Everything stays on your machine.

## Install

### Via Homebrew (recommended)

```bash
brew tap qouter/tap
brew install herd
```

Hooks are automatically installed. Launch with:

```bash
herd open
```

That's it! Start a Claude Code session and watch the menu bar update.

### Manual installation

#### Prerequisites

- macOS 13+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `jq` and `socat` (install with `brew install jq socat`)
- Swift 5.9+ (included with Xcode or Xcode Command Line Tools)

#### Build & install

```bash
git clone https://github.com/Qouter/herd.git
cd herd

# Build the app
./build.sh

# Copy to Applications
cp -r build/Herd.app /Applications/

# Install Claude Code hooks
./install.sh

# Launch
open /Applications/Herd.app
```

## Menu bar

When no agents are running, you'll see a simple `🤖` icon.

As agents start, the icon shows live counters:

| State | Menu bar |
|-------|----------|
| No agents | `🤖` |
| 3 agents, all working | `🤖 3` |
| 3 agents, 1 waiting | `🤖 3 \| ⏳ 1` |

Click the icon to open the dropdown:

```
┌─────────────────────────────────┐
│  Herd                    ⚙️     │
├─────────────────────────────────┤
│                                 │
│  🟢 ~/myproject                 │
│     Working...          [Open]  │
│                                 │
│  🟡 ~/other-project             │
│     "Refactored the auth..."    │
│     Waiting for you     [Open]  │
│                                 │
├─────────────────────────────────┤
│  2 active · 1 waiting    Quit   │
└─────────────────────────────────┘
```

- **🟢 Green** — agent is working
- **🟡 Orange** — agent finished and is waiting for your input
- **[Open]** — opens Terminal.app (or iTerm2 if installed) at the agent's directory
- Last message from the agent is shown when idle

## Hooks

Herd installs four async hooks in `~/.claude/settings.json`:

| Hook | Event | What it does |
|------|-------|-------------|
| `on-session-start.sh` | `SessionStart` | Registers a new agent |
| `on-session-end.sh` | `SessionEnd` | Removes the agent |
| `on-stop.sh` | `Stop` | Marks agent as idle, extracts last message from transcript |
| `on-prompt.sh` | `UserPromptSubmit` | Marks agent as active again |

All hooks are `async: true` — they never block Claude Code.

## Uninstall

### If installed via Homebrew

```bash
# Remove hooks first
herd uninstall-hooks

# Uninstall the app
brew uninstall herd
brew untap qouter/tap  # optional
```

### If installed manually

```bash
# Remove hooks from Claude Code
./uninstall.sh

# Remove the app
rm -rf /Applications/Herd.app
```

## Project structure

```
herd/
├── hooks/                    # Claude Code hook scripts
│   ├── on-session-start.sh
│   ├── on-session-end.sh
│   ├── on-stop.sh
│   └── on-prompt.sh
├── app/                      # Swift menu bar app
│   ├── Package.swift
│   └── Sources/Herd/
│       ├── ClaudeDeckApp.swift
│       ├── MenuBarController.swift
│       ├── AgentSession.swift
│       ├── AgentStore.swift
│       ├── SocketServer.swift
│       ├── AgentListView.swift
│       ├── AgentRowView.swift
│       └── TerminalLauncher.swift
├── install.sh
├── uninstall.sh
└── build.sh
```

## Roadmap

- [x] Homebrew tap: `brew install herd`
- [ ] Notification sound when an agent goes idle
- [ ] Keyboard shortcut to open the popover
- [ ] Jump to exact terminal tab (iTerm2, Warp, VS Code)
- [ ] Show project name (from package.json, Cargo.toml, etc.)
- [ ] Launch at Login toggle
- [ ] Auto-cleanup stale sessions (currently 5 min timeout)

## License

MIT
