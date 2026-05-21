# Ingest Source

**Trigger:** "ingest raw/[filename]" or "ingest [filename]"
**Goal:** Source is summarized, wiki pages created, index updated. Knowledge is findable.
**Inputs required:** File dropped into `raw/` before triggering.

## Step 0 — Extract Raw Content by File Type

Before reading anything, check the file extension and use the correct extraction method:

| Format | Method |
|---|---|
| `.md`, `.txt`, `.html` | Read tool directly |
| `.pdf` | Read tool — pass `pages:` param for large PDFs (>10 pages) |
| `.pptx`, `.docx` | `tools/extract-office.sh raw/<file>` via Bash tool |
| `.png`, `.jpg`, `.gif` | Read tool (vision) |
| Other | Check `workflows/ingestion-errors.md` for known fixes; if not there, diagnose and add |

**Never attempt pip install, venv creation, or LibreOffice conversion** for Office files. `extract-office.sh` handles PPTX and DOCX natively via `unzip` + XML grep with no dependencies.

## Steps

1. Extract content using the method above
2. State 3 key takeaways in 2-3 sentences — discuss with the user before writing anything
3. Create `wiki/sources/[slug].md` — include: title, source path, date ingested, summary, key concepts, entities, links to related pages
4. For each new entity (person, org, product): create or update `wiki/entities/[name].md`
5. For each new concept (idea, framework, technique): create or update `wiki/concepts/[name].md`
6. Update `wiki/_index.md` — add all new/updated pages with one-line summaries
7. Update `wiki/_hot.md` if source is directly relevant to current priorities (keep under 500 tokens)
8. Append to `log.md`: `## [YYYY-MM-DD] ingest | [Source Title]`
9. Commit and push all changes to remote (see Session End protocol in CLAUDE.md)

## Known Edge Cases

- **File not found:** Check capitalization. Ask user to confirm filename.
- **Very long source (50+ pages):** Read in chunks. Summarize per section before synthesizing. Note in sources/ page that it was read in sections.
- **Source partially overlaps existing page:** Update the existing page rather than creating a duplicate. Note the update in log.md.
- **Same concept appears across multiple sources:** One concept page, multiple sources linked. Never split a concept page by source.
- **Unknown file type or extraction error:** See `workflows/ingestion-errors.md`. If error is new, diagnose, fix, then follow the Self-Learning Protocol below.

## Self-Learning Protocol

When any ingestion step fails with an error not already covered above:

1. **Diagnose** — identify root cause (missing tool, wrong file path, encoding issue, etc.)
2. **Fix** — find the simplest fix that works on this system without new dependencies
3. **Present** — describe the error, what was tried, and what worked; ask the user if they want to enhance the fix
4. **After user confirms** — update this workflow (Step 0 or edge cases) with the fix, and append a dated entry to `workflows/ingestion-errors.md`

Do not skip step 4. If a fix is not written into the SOP, the next session will rediscover the same error.

**Last updated:** 2026-05-20
