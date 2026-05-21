#!/bin/bash
# morning-brief.sh
# Runs at 7am daily. Writes context/today.md with date, calendar events,
# upcoming deadlines, and this-week tasks.
# BRAIN_DIR is set by setup.sh — do not edit manually.

BRAIN_DIR="BRAIN_DIR_PLACEHOLDER"
OUTPUT="$BRAIN_DIR/context/today.md"
PRIORITIES="$BRAIN_DIR/context/priorities.md"

TODAY=$(date '+%A, %B %d, %Y')
GENERATED=$(date '+%Y-%m-%d %I:%M %p %Z')

# Parse Hard Deadlines section from priorities.md
DEADLINES=$(awk '/^## Hard Deadlines/{found=1; next} found && /^## /{exit} found && /^- /{print}' "$PRIORITIES")

# Parse This Week tasks (non-completed rows)
THIS_WEEK=$(awk '/^## This Week/{found=1; next} found && /^## /{exit} found && /^\|/{print}' "$PRIORITIES" | grep -v "~~" | grep -v "Status" | grep -v "^|-")

# Fetch today's calendar events (optional — fails gracefully if not set up)
CALENDAR=$(python3 "$BRAIN_DIR/tools/calendar_fetch.py" 2>/dev/null || echo "(Calendar unavailable — see README for setup)")

cat > "$OUTPUT" << EOF
# today.md
_Auto-generated: ${GENERATED}. Do not edit — overwritten each morning._

## Today
**${TODAY}**

## Calendar
${CALENDAR}

## Hard Deadlines
${DEADLINES}

## This Week
${THIS_WEEK}
EOF

echo "[morning-brief] context/today.md updated at ${GENERATED}"
