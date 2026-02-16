#!/usr/bin/env python3
"""Herder hook: Stop — marks agent as idle, extracts last assistant message."""
import json, os, socket, sys, time

SOCKET_PATH = "/tmp/herder.sock"

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = data.get("session_id", "")
if not session_id:
    sys.exit(0)

# Extract last assistant message from transcript
last_message = ""
transcript_path = data.get("transcript_path", "")
if transcript_path and os.path.isfile(transcript_path):
    try:
        with open(transcript_path, "r") as f:
            lines = f.readlines()
        for line in reversed(lines[-20:]):
            try:
                entry = json.loads(line)
                msg_obj = entry.get("message", {})
                if msg_obj.get("role") == "assistant":
                    content = msg_obj.get("content", [])
                    if content and isinstance(content, list):
                        text = content[0].get("text", "")
                        if text:
                            last_message = text.replace("\n", " ")[:100]
                            break
            except Exception:
                continue
    except Exception:
        pass

msg = json.dumps({
    "event": "agent_idle",
    "session_id": session_id,
    "last_message": last_message,
    "transcript_path": transcript_path,
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
