#!/usr/bin/env bash
# Herd - Hook Installer
# Installs Claude Code hooks that communicate with the Herd menu bar app

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks/herd"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

UNINSTALL=false
if [[ "${1:-}" == "--uninstall" ]]; then
  UNINSTALL=true
fi

echo -e "${GREEN}Herd Hook Installer${NC}"
echo ""

if [[ "$UNINSTALL" == true ]]; then
  echo "Uninstalling Herd hooks..."
  
  if [[ -f "$SETTINGS_FILE" ]]; then
    python3 - <<'EOF'
import json, sys, os

settings_file = os.path.expanduser("~/.claude/settings.json")
try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    print("⚠️  Could not read settings.json")
    sys.exit(0)

hooks = settings.get("hooks", {})
changed = False

for event in ["SessionStart", "SessionEnd", "Stop", "UserPromptSubmit"]:
    if event in hooks:
        original = hooks[event]
        filtered = []
        for group in original:
            group_hooks = [h for h in group.get("hooks", []) if "herd" not in h.get("command", "")]
            if group_hooks:
                filtered.append({"hooks": group_hooks})
        if filtered:
            hooks[event] = filtered
        else:
            del hooks[event]
        changed = True

if changed:
    settings["hooks"] = hooks
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
    print("✓ Removed hooks from settings.json")
else:
    print("✓ No hooks to remove")
EOF
  fi
  
  if [[ -d "$HOOKS_DIR" ]]; then
    rm -rf "$HOOKS_DIR"
    echo -e "${GREEN}✓${NC} Removed hook scripts from $HOOKS_DIR"
  fi
  
  echo ""
  echo -e "${GREEN}✓ Herd hooks uninstalled successfully${NC}"
  exit 0
fi

# === INSTALL ===

mkdir -p "$HOOKS_DIR"

echo "Installing hook scripts..."
for script in on-session-start.sh on-session-end.sh on-stop.sh on-prompt.sh; do
  cp "$SCRIPT_DIR/hooks/$script" "$HOOKS_DIR/"
  chmod +x "$HOOKS_DIR/$script"
  echo -e "  ${GREEN}✓${NC} $script"
done

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "{}" > "$SETTINGS_FILE"
  echo -e "${YELLOW}⚠${NC}  Created new settings.json"
fi

echo ""
echo "Registering hooks in ~/.claude/settings.json..."

python3 - <<EOF
import json, os

settings_file = os.path.expanduser("$SETTINGS_FILE")
hooks_dir = os.path.expanduser("$HOOKS_DIR")

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

if "hooks" not in settings:
    settings["hooks"] = {}

hooks = settings["hooks"]

hook_configs = {
    "SessionStart": f"{hooks_dir}/on-session-start.sh",
    "SessionEnd": f"{hooks_dir}/on-session-end.sh",
    "Stop": f"{hooks_dir}/on-stop.sh",
    "UserPromptSubmit": f"{hooks_dir}/on-prompt.sh"
}

for event, command in hook_configs.items():
    if event not in hooks:
        hooks[event] = []
    
    exists = any(
        "herd" in h.get("command", "")
        for group in hooks[event]
        for h in group.get("hooks", [])
    )
    
    if not exists:
        hooks[event].append({
            "hooks": [{
                "type": "command",
                "command": command,
                "async": True
            }]
        })

settings["hooks"] = hooks
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("✓ Hooks registered successfully")
EOF

echo ""
echo -e "${GREEN}✓ Herd hooks installed successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Build and launch Herd.app"
echo "  2. Start a Claude Code session"
echo "  3. Check the menu bar for active agents"
echo ""
echo "To uninstall: ./install.sh --uninstall"
