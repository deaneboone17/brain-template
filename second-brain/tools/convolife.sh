#!/usr/bin/env bash
# Check context window usage for the current project
# Usage: ./tools/convolife.sh

PROJECT_PATH="$(pwd)"
# Claude Code stores sessions with path separators replaced by hyphens
SAFE_PATH=$(echo "$PROJECT_PATH" | tr '/' '-' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$SAFE_PATH"

if [ ! -d "$SESSION_DIR" ]; then
    echo "No session data found for this project."
    echo "Looked in: $SESSION_DIR"
    exit 0
fi

# Find the most recent session file
LATEST=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
    echo "No active session found."
    exit 0
fi

# Get the last cache_read_input_tokens value
TOKENS=$(grep -o '"cache_read_input_tokens":[0-9]*' "$LATEST" 2>/dev/null | tail -1 | grep -o '[0-9]*')

if [ -z "$TOKENS" ]; then
    echo "Could not determine token usage. Session may be fresh."
    exit 0
fi

MAX=200000
PERCENT=$((TOKENS * 100 / MAX))
REMAINING=$(( (MAX - TOKENS) / 1000 ))

echo "Context window: ${PERCENT}% used (~${REMAINING}k tokens remaining)"

if [ "$PERCENT" -gt 80 ]; then
    echo "⚠ WARNING: Context is getting full. Consider running checkpoint + /newchat."
elif [ "$PERCENT" -gt 60 ]; then
    echo "△ Moderate usage. Safe for small operations. Avoid large file reads."
else
    echo "✓ Plenty of room."
fi
