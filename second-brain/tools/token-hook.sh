#!/usr/bin/env bash
# Stop hook: parse session JSONL, update ~/.claude/token-stats.json
# Claude Code calls this after each response via the Stop hook event.
# Tracks token usage and cost per session and lifetime.

set -euo pipefail

STATE_FILE="$HOME/.claude/token-stats.json"
HOOK_INPUT=$(cat)

python3 - "$STATE_FILE" "$HOOK_INPUT" << 'PYEOF'
import json, os, sys, glob
from datetime import datetime, timezone

state_file = sys.argv[1]
hook_input_str = sys.argv[2] if len(sys.argv) > 2 else "{}"

# Pricing: claude-sonnet-4-6 per token
# Update these if you use a different model
PRICE = {
    "input":       3.00  / 1_000_000,
    "output":      15.00 / 1_000_000,
    "cache_write": 3.75  / 1_000_000,
    "cache_read":  0.30  / 1_000_000,
}
CONTEXT_MAX = 200_000

try:
    hook_data = json.loads(hook_input_str)
except Exception:
    hook_data = {}

session_id = hook_data.get("session_id", "")
transcript = hook_data.get("transcript_path", "")

if not transcript or not os.path.isfile(transcript):
    pattern = os.path.expanduser("~/.claude/projects/-home-*/*.jsonl")
    candidates = sorted(glob.glob(pattern), key=os.path.getmtime, reverse=True)
    if candidates:
        transcript = candidates[0]

if not transcript or not os.path.isfile(transcript):
    sys.exit(0)

input_tok = output_tok = cache_write = cache_read = 0
max_context = 0

with open(transcript) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue

        if not session_id:
            session_id = obj.get("sessionId", "")

        usage = obj.get("usage") or (obj.get("message") or {}).get("usage") or {}
        if not isinstance(usage, dict):
            continue

        i   = usage.get("input_tokens", 0)
        o   = usage.get("output_tokens", 0)
        cw  = usage.get("cache_creation_input_tokens", 0)
        cr  = usage.get("cache_read_input_tokens", 0)

        input_tok   += i
        output_tok  += o
        cache_write += cw
        cache_read  += cr

        if cr > max_context:
            max_context = cr

total_tokens = input_tok + output_tok + cache_write + cache_read
session_cost = (
    input_tok   * PRICE["input"] +
    output_tok  * PRICE["output"] +
    cache_write * PRICE["cache_write"] +
    cache_read  * PRICE["cache_read"]
)
ctx_pct = int(max_context * 100 / CONTEXT_MAX)

state = {
    "current_session_id":     "",
    "current_session_cost":   0.0,
    "current_context_pct":    0,
    "current_context_tokens": 0,
    "current_input_tokens":   0,
    "current_output_tokens":  0,
    "current_total_tokens":   0,
    "lifetime_cost":          0.0,
    "lifetime_sessions":      0,
    "updated_at":             "",
}
if os.path.isfile(state_file):
    try:
        with open(state_file) as f:
            saved = json.load(f)
        state.update(saved)
    except Exception:
        pass

if session_id and session_id != state.get("current_session_id", ""):
    prev_cost = state.get("current_session_cost", 0.0)
    if prev_cost > 0:
        state["lifetime_cost"]     = state.get("lifetime_cost", 0.0) + prev_cost
        state["lifetime_sessions"] = state.get("lifetime_sessions", 0) + 1

state["current_session_id"]     = session_id
state["current_session_cost"]   = round(session_cost, 6)
state["current_context_pct"]    = ctx_pct
state["current_context_tokens"] = max_context
state["current_input_tokens"]   = input_tok
state["current_output_tokens"]  = output_tok
state["current_total_tokens"]   = total_tokens
state["updated_at"]             = datetime.now(timezone.utc).isoformat()

with open(state_file, "w") as f:
    json.dump(state, f, indent=2)
PYEOF
