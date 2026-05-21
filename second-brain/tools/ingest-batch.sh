#!/usr/bin/env bash
set -euo pipefail

# Batch ingest: processes each file in a directory through the two-phase pipeline
# Usage: ./tools/ingest-batch.sh raw/some-folder/
# Or:    ./tools/ingest-batch.sh raw/file1.md raw/file2.pdf raw/file3.md

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INGEST="$SCRIPT_DIR/ingest.sh"
COUNT=0
ERRORS=0

for SOURCE in "$@"; do
    if [ -d "$SOURCE" ]; then
        # If argument is a directory, process all files in it
        for FILE in "$SOURCE"/*; do
            [ -f "$FILE" ] || continue
            COUNT=$((COUNT + 1))
            echo ""
            echo "━━━ Processing $COUNT: $(basename "$FILE") ━━━"
            if "$INGEST" "$FILE"; then
                echo "✓ Done: $(basename "$FILE")"
            else
                echo "✗ Failed: $(basename "$FILE")"
                ERRORS=$((ERRORS + 1))
            fi
            # Brief pause between files to let sessions fully close
            sleep 2
        done
    elif [ -f "$SOURCE" ]; then
        COUNT=$((COUNT + 1))
        echo ""
        echo "━━━ Processing $COUNT: $(basename "$SOURCE") ━━━"
        if "$INGEST" "$SOURCE"; then
            echo "✓ Done: $(basename "$SOURCE")"
        else
            echo "✗ Failed: $(basename "$SOURCE")"
            ERRORS=$((ERRORS + 1))
        fi
        sleep 2
    else
        echo "Warning: $SOURCE not found, skipping."
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "  Batch complete: $COUNT processed, $ERRORS errors"
echo "═══════════════════════════════════════════"
