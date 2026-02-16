#!/usr/bin/env python3
"""Herder hook: SessionEnd — removes an agent session."""
import json, os, socket, sys, time

SOCKET_PATH = "/tmp/herder.sock"

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = data.get("session_id", "")
if not session_id:
    sys.exit(0)

msg = json.dumps({
    "event": "session_end",
    "session_id": session_id,
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
