#!/bin/bash
# Extract readable text from Office XML formats (PPTX, DOCX).
# No Python, no pip, no LibreOffice required — only bash + unzip (always available on Ubuntu).
#
# Usage:
#   ./tools/extract-office.sh raw/MyFile.pptx
#   ./tools/extract-office.sh raw/MyDoc.docx
#
# Output: plain text to stdout. Pipe to a file or read in Claude Code via Bash tool.

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file.pptx|file.docx>" >&2
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE" >&2
    exit 1
fi

TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

EXT_LOWER=$(echo "${FILE##*.}" | tr '[:upper:]' '[:lower:]')

unzip -q "$FILE" -d "$TMPDIR" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Could not unzip $FILE — is it a valid Office file?" >&2
    exit 1
fi

case "$EXT_LOWER" in
    pptx)
        # Text lives in <a:t> tags within ppt/slides/slide*.xml
        # Slides are numbered but not necessarily in order by filename; sort numerically
        for slide in $(ls "$TMPDIR/ppt/slides/slide"*.xml 2>/dev/null | sort -t'e' -k2 -n); do
            SLIDE_NUM=$(basename "$slide" .xml | sed 's/slide//')
            CONTENT=$(grep -oP '(?<=<a:t>)[^<]+' "$slide" 2>/dev/null | grep -v '^[[:space:]]*$' | tr '\n' ' ')
            if [ -n "$CONTENT" ]; then
                echo "-- Slide $SLIDE_NUM --"
                echo "$CONTENT"
                echo
            fi
        done
        ;;
    docx)
        # Text lives in <w:t> tags within word/document.xml
        # Use <w:t[^>]*>\K to handle tags with attributes (e.g. xml:space="preserve")
        grep -oP '<w:t[^>]*>\K[^<]+' "$TMPDIR/word/document.xml" 2>/dev/null | grep -v '^[[:space:]]*$'
        ;;
    *)
        echo "ERROR: Unsupported format .$EXT_LOWER (supported: pptx, docx)" >&2
        exit 1
        ;;
esac
