# Herder 🐑

**A macOS menu bar app that shows how many Claude Code agents are running and which ones need your attention.**

<p align="center">
  <code>🤖 3 | ⏳ 1</code>
</p>

Running multiple Claude Code agents across terminals? Herder sits in your menu bar and tells you at a glance:

- **How many agents** are currently running
- **Which ones are waiting** for your input
- **What they last said** — so you know what needs attention
- **One click** to jump to any agent's terminal

No network calls. No API keys. Everything stays on your machine.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Qouter/herder/main/install.sh | bash
```

One command. Installs the app, CLI, and Claude Code hooks. Done.

<details>
<summary>Or via Homebrew</summary>

```bash
brew tap qouter/tap
brew install herder
```
</details>

## How it works

Herder uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to track agent lifecycle events. Four lightweight bash scripts fire on `SessionStart`, `SessionEnd`, `Stop`, and `UserPromptSubmit`, sending JSON messages to a local Unix socket. The menu bar app listens on that socket and updates in real time.

```
Claude Code hooks  →  /tmp/herder.sock  →  Menu bar app
(bash + jq)            (Unix socket)        (Swift + SwiftUI)
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
│  Herder 🐑              v0.4.0 │
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

> **Note:** Only sessions started after installing Herder will appear. Restart existing Claude Code sessions to track them.

## Commands

```bash
herder open              # Launch the app
herder update            # Update to latest version
herder status            # Check configuration
herder install-hooks     # Install/reinstall Claude Code hooks
herder uninstall-hooks   # Remove hooks
herder uninstall         # Remove everything
herder version           # Show installed version
```

## Update

```bash
herder update
```

Downloads the latest release, replaces the app, done. No brew cache issues.

## Hooks

Herder installs four async hooks in `~/.claude/settings.json`:

| Hook | Event | What it does |
|------|-------|-------------|
| `on-session-start.sh` | `SessionStart` | Registers a new agent |
| `on-session-end.sh` | `SessionEnd` | Removes the agent |
| `on-stop.sh` | `Stop` | Marks agent as idle, extracts last message from transcript |
| `on-prompt.sh` | `UserPromptSubmit` | Marks agent as active again |

All hooks are `async: true` — they never block Claude Code.

## Prerequisites

- macOS 13+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- `jq` and `socat` (`brew install jq socat`)

## Uninstall

```bash
herder uninstall
```

Removes the app, CLI, and hooks. Clean.

## Roadmap

- [ ] Detect existing running sessions on launch
- [ ] Notification sound when an agent goes idle
- [ ] Keyboard shortcut to open the popover
- [ ] Jump to exact terminal tab (iTerm2, Warp, VS Code integrated terminal)
- [ ] Show project name (from package.json, Cargo.toml, etc.)
- [ ] Launch at Login toggle
- [ ] Homebrew cask for drag-and-drop install

## License

MIT
