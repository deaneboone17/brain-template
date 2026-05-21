#!/bin/bash
# setup.sh — one-time setup for brain-template
# Run from the repo root: bash setup.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN_DIR="$REPO_DIR/second-brain"

echo ""
echo "═══════════════════════════════════════════"
echo "  Brain Template Setup"
echo "═══════════════════════════════════════════"
echo ""
echo "Repo root:   $REPO_DIR"
echo "Brain dir:   $BRAIN_DIR"
echo ""

# ── 1. Substitute BRAIN_DIR_PLACEHOLDER in scripts ───────────────────────────
echo "[1/4] Updating BRAIN_DIR paths in scripts..."

sed -i "s|BRAIN_DIR_PLACEHOLDER|$BRAIN_DIR|g" "$BRAIN_DIR/tools/morning-brief.sh"
sed -i "s|BRAIN_DIR_PLACEHOLDER|$BRAIN_DIR|g" "$BRAIN_DIR/tools/stale-check.sh"
sed -i "s|BRAIN_DIR_PLACEHOLDER|$REPO_DIR|g"  "$REPO_DIR/.claude/settings.json"

echo "    Done."

# ── 2. Make scripts executable ────────────────────────────────────────────────
echo "[2/4] Setting executable permissions on tools..."
chmod +x "$BRAIN_DIR/tools/"*.sh
echo "    Done."

# ── 3. Add cron jobs ──────────────────────────────────────────────────────────
echo "[3/4] Adding cron jobs..."

MORNING_CRON="0 7 * * * $BRAIN_DIR/tools/morning-brief.sh >> $BRAIN_DIR/tools/morning-brief.log 2>&1"
STALE_CRON="5 7 * * 0 $BRAIN_DIR/tools/stale-check.sh >> $BRAIN_DIR/tools/stale-check.log 2>&1"

# Add only if not already present
( crontab -l 2>/dev/null | grep -v "morning-brief\|stale-check" ; echo "$MORNING_CRON" ; echo "$STALE_CRON" ) | crontab -

echo "    morning-brief.sh: daily at 7:00am"
echo "    stale-check.sh:   Sundays at 7:05am"

# ── 4. Create today.md placeholder ───────────────────────────────────────────
echo "[4/4] Creating initial today.md..."
TODAY=$(date '+%A, %B %d, %Y')
cat > "$BRAIN_DIR/context/today.md" << EOF
# today.md
_Auto-generated: $(date '+%Y-%m-%d %I:%M %p %Z'). Overwritten each morning by morning-brief.sh._

## Today
**${TODAY}**

## Calendar
(Calendar unavailable — see README for Google Calendar setup)

## Hard Deadlines
(Populated from context/priorities.md once you fill it in)

## This Week — Income Tasks
(Populated from context/priorities.md once you fill it in)
EOF

echo "    Done."
echo ""
echo "═══════════════════════════════════════════"
echo "  Setup complete."
echo ""
echo "  Next steps:"
echo "  1. Fill in second-brain/context/ files (or run the onboarding prompt)"
echo "  2. Run 'claude' in this directory to start"
echo "  3. Optional: set up Google Calendar (see README)"
echo "═══════════════════════════════════════════"
echo ""
