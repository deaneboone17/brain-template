#!/bin/bash
# stale-check.sh
# Runs Sundays at 7:05am (5 min after morning-brief to avoid race condition).
# Scans the second brain for stale pages and known contradiction patterns.
# Appends a Maintenance section to context/today.md when issues are found.
# BRAIN_DIR is set by setup.sh — do not edit manually.

BRAIN_DIR="BRAIN_DIR_PLACEHOLDER"
WIKI_DIR="$BRAIN_DIR/wiki"
OUTPUT="$BRAIN_DIR/context/today.md"
STALE_DAYS=30
ISSUES=()

# ── 1. Pages not touched in $STALE_DAYS days ─────────────────────────────────
while IFS= read -r -d '' file; do
    rel="${file#$BRAIN_DIR/}"
    ISSUES+=("STALE (>${STALE_DAYS}d): $rel")
done < <(find "$WIKI_DIR/entities" "$WIKI_DIR/meta" "$BRAIN_DIR/context" \
    -name "*.md" \
    -not -name "_*" \
    -mtime +"$STALE_DAYS" \
    -print0 2>/dev/null)

# ── 2. Known contradiction keywords ──────────────────────────────────────────
# Add patterns here as your knowledge evolves.
# Format: "regex_pattern:Human-readable correction note"
# The regex uses grep -iE syntax. Use \| for OR.
PATTERNS=(
    # Example: "old-term:Use new-term instead"
    # "old company name:Company was rebranded — update references"
)

for entry in "${PATTERNS[@]}"; do
    pattern="${entry%%:*}"
    note="${entry##*:}"
    matches=$(grep -rl --include="*.md" -iE "$pattern" \
        "$WIKI_DIR/entities" "$WIKI_DIR/sources" "$WIKI_DIR/meta" \
        "$BRAIN_DIR/context" 2>/dev/null \
        | grep -v "_staging" | grep -v "raw/")
    if [ -n "$matches" ]; then
        while IFS= read -r match; do
            rel="${match#$BRAIN_DIR/}"
            ISSUES+=("CONTRADICTION [$note]: $rel")
        done <<< "$matches"
    fi
done

# ── 3. Append to today.md if issues found ────────────────────────────────────
if [ ${#ISSUES[@]} -gt 0 ]; then
    {
        echo ""
        echo "---"
        echo "## Maintenance Flags ($(date '+%Y-%m-%d'))"
        echo "_Run \`stale-check.sh\` output. Review and fix before next session._"
        echo ""
        for issue in "${ISSUES[@]}"; do
            echo "- $issue"
        done
    } >> "$OUTPUT"
    echo "[stale-check] ${#ISSUES[@]} issue(s) appended to today.md"
else
    echo "[stale-check] No issues found."
fi
