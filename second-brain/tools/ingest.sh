#!/usr/bin/env bash
set -euo pipefail

# Two-phase ingest: Haiku extracts, Sonnet integrates.
# Usage: ./tools/ingest.sh <path-to-raw-source>
# Example: ./tools/ingest.sh raw/meeting-notes.md

SOURCE="$1"
BASENAME=$(basename "$SOURCE" | sed 's/\.[^.]*$//')
STAGING="wiki/_staging/${BASENAME}.extraction.md"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure staging directory exists (git-ignored, won't survive a fresh clone)
mkdir -p "$(dirname "$0")/../wiki/_staging"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source file not found: $SOURCE"
    exit 1
fi

if [ -f "$STAGING" ]; then
    echo "Staging file already exists: $STAGING"
    echo "Run Phase 2 integration, or delete it to re-extract."
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "  PHASE 1: Extract with Haiku"
echo "  Source: $SOURCE"
echo "═══════════════════════════════════════════"

claude --model claude-haiku-4-5 --print -p "
You are a document extraction agent. Your ONLY job is to read one source document and produce a structured extraction file. You do NOT modify the wiki. You do NOT read the index. You ONLY read the source and write the extraction.

Read the file at: $SOURCE

Then create the file: $STAGING

Use this exact structure:

---
source_file: $SOURCE
extracted_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
word_count: <approximate word count of source>
source_type: <article|transcript|paper|book-chapter|notes|report|other>
---

## Summary
<3-5 sentences capturing the core content. What is this source about? What are the key conclusions or takeaways?>

## Key Entities
<For each entity (person, organization, product, project), one line:>
- **<Name>** (<type>): <one sentence description and relevance>

## Key Concepts
<For each concept, framework, or technique discussed:>
- **<Name>**: <one sentence definition or explanation>

## Key Facts and Claims
<Numbered list of specific, extractable facts. Include enough context that each fact stands alone:>
1. <fact with context>
2. <fact with context>
...

## Relationships
<Pairs of entities/concepts and how they relate:>
- <Entity A> → <Entity B>: <relationship description>

## Notable Quotes
<Max 5 direct quotes that are worth preserving. Include surrounding context:>
> \"<quote>\" — <speaker/author>, <context>

## Open Questions
<What does this source leave unanswered? What gaps exist? What would be worth investigating further?>

## Suggested Wiki Pages
<Based on the content, which new wiki pages should be created or which existing pages likely need updating? List page names and why:>
- <page-name>: <reason>

IMPORTANT RULES:
- Do NOT read any files in wiki/. Only read the source file.
- Do NOT modify any existing files. Only create the staging file.
- Keep the extraction under 3000 words regardless of source length.
- Be factual and specific. No filler. No commentary on the process.
- If the source contains code, extract the purpose and design decisions, not the code itself.
"

if [ ! -f "$STAGING" ]; then
    echo "Error: Phase 1 failed — no extraction file created."
    exit 1
fi

EXTRACTION_SIZE=$(wc -c < "$STAGING")
echo ""
echo "✓ Phase 1 complete. Extraction: $STAGING ($EXTRACTION_SIZE bytes)"
echo ""
echo "═══════════════════════════════════════════"
echo "  PHASE 2: Integrate with Sonnet"
echo "═══════════════════════════════════════════"

claude --print -p "
You are a wiki integration agent. Your job is to read a pre-extracted summary of a source document and integrate it into the existing wiki. You do NOT read the original raw source — the extraction contains everything you need.

STEP 1: Read the extraction file at: $STAGING
STEP 2: Read wiki/_index.md to understand existing wiki structure.
STEP 3: Read wiki/_hot.md if it exists.
STEP 4: Based on the 'Suggested Wiki Pages' section and the index, identify which 1-3 existing wiki pages need updating. Read only those pages.
STEP 5: Create new wiki pages as needed:
  - Source summary → wiki/sources/${BASENAME}.md
  - New entity pages → wiki/entities/<entity-name>.md
  - New concept pages → wiki/concepts/<concept-name>.md
  - If the extraction suggests comparisons or analysis → wiki/comparisons/ or wiki/meta/
STEP 6: Update existing wiki pages with new cross-references and information from this source. Add [[wiki-links]] to connect related pages.
STEP 7: Update wiki/_index.md with all new and modified pages.
STEP 8: Append an entry to log.md:
  ## [$(date -u +%Y-%m-%d)] ingest | ${BASENAME}
  - Source: $SOURCE
  - Pages created: <list>
  - Pages updated: <list>
  - Key additions: <1-2 sentences>
STEP 9: Update wiki/_hot.md with the most relevant recent context from this source.
STEP 10: Delete the staging file: $STAGING

IMPORTANT RULES:
- Do NOT read any files in raw/. The extraction has everything you need.
- Read at most 3 existing wiki pages for cross-referencing.
- Keep source summary pages under 1500 words.
- Use [[wiki-links]] for all cross-references between pages.
- Every new page must appear in _index.md.
"

echo ""
echo "✓ Phase 2 complete. Source integrated into wiki."
echo ""
echo "Run 'claude' and ask about the new content to verify."
