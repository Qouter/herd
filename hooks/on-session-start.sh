#!/usr/bin/env python3
"""Herder hook: SessionStart — registers a new agent session."""
import json, os, socket, sys, time

SOCKET_PATH = "/tmp/herder.sock"

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = data.get("session_id", "")
cwd = data.get("cwd", "")
if not session_id or not cwd:
    sys.exit(0)

# Detect terminal by walking up the process tree
terminal_pid = ""
terminal_app = ""
try:
    pid = os.getppid()
    for _ in range(10):
        if pid <= 1:
            break
        comm = os.popen(f"ps -o comm= -p {pid} 2>/dev/null").read().strip()
        comm_lower = comm.lower()
        if "warp" in comm_lower:
            terminal_pid, terminal_app = str(pid), "warp"; break
        elif "iterm" in comm_lower:
            terminal_pid, terminal_app = str(pid), "iterm2"; break
        elif comm == "Terminal" or "terminal" in comm_lower:
            terminal_pid, terminal_app = str(pid), "terminal"; break
        elif "cursor" in comm_lower:
            terminal_pid, terminal_app = str(pid), "cursor"; break
        elif "code" in comm_lower:
            terminal_pid, terminal_app = str(pid), "vscode"; break
        ppid = os.popen(f"ps -o ppid= -p {pid} 2>/dev/null").read().strip()
        pid = int(ppid) if ppid.isdigit() else 0
except Exception:
    pass

tty = ""
try:
    tty = os.ttyname(0)
except Exception:
    pass

msg = json.dumps({
    "event": "session_start",
    "session_id": session_id,
    "cwd": cwd,
    "tty": tty,
    "terminal_pid": terminal_pid,
    "terminal_app": terminal_app,
    "timestamp": int(time.time()),
})

if os.path.exists(SOCKET_PATH):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(SOCKET_PATH)
        s.sendall((msg + "\n").encode())
        s.close()
    except Exception:
        pass
