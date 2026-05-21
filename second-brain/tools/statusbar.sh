#!/usr/bin/env bash
# Status bar: reads ~/.claude/token-stats.json and prints one line.
# Registered as Claude Code statusCommand in .claude/settings.json.
# Shows: context window %, session cost, lifetime cost.

STATE_FILE="$HOME/.claude/token-stats.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "ctx --  |  session --  |  lifetime --"
    exit 0
fi

python3 - "$STATE_FILE" << 'PYEOF'
import json, sys, os

state_file = sys.argv[1]

try:
    with open(state_file) as f:
        s = json.load(f)
except Exception:
    print("ctx --  |  session --  |  lifetime --")
    sys.exit(0)

ctx_pct     = s.get("current_context_pct", 0)
sess_cost   = s.get("current_session_cost", 0.0)
lifetime    = s.get("lifetime_cost", 0.0) + sess_cost
sessions    = s.get("lifetime_sessions", 0) + 1
out_tok     = s.get("current_output_tokens", 0)
total_tok   = s.get("current_total_tokens", 0)

filled = ctx_pct // 10
bar = "█" * filled + "░" * (10 - filled)

if ctx_pct >= 80:
    warn = " ⚠"
elif ctx_pct >= 60:
    warn = " △"
else:
    warn = ""

def fmt_k(n):
    return f"{n/1000:.1f}k" if n >= 1000 else str(n)

print(
    f"ctx [{bar}] {ctx_pct}%{warn}"
    f"  |  sess ${sess_cost:.4f} ({fmt_k(out_tok)} out)"
    f"  |  lifetime ${lifetime:.2f} / {sessions} sessions"
)
PYEOF
