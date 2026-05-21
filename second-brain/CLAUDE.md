# Second Brain — Schema

@context/me.md
@context/work.md
@context/priorities.md
@context/goals.md

## Layers
A second brain has four layers. All four must be present for a new brain deployment to be complete.

| Layer | What it does | Key files |
|---|---|---|
| Knowledge | Stores and retrieves information | wiki/, context/, raw/ |
| Behavior | Governs how Claude operates | CLAUDE.md, workflows/, .claude/rules/ |
| Automation | Keeps the brain alive and time-aware without manual input | tools/morning-brief.sh, .claude/settings.json, crontab |
| Access | Controls who can reach the brain and how | Local only (default); internet + auth for shared brains |

## Automation Layer

### Components
| Component | Type | What it does | Config |
|---|---|---|---|
| Timestamp injection | UserPromptSubmit hook | Injects current time on every message — enables time awareness mid-session and after breaks | `.claude/settings.json` |
| Morning brief | Cron job (7am daily) | Writes `context/today.md` with today's date, calendar events, hard deadlines, and this-week tasks | `tools/morning-brief.sh`, crontab |
| Staleness check | Cron job (7:05am Sundays) | Scans wiki for pages not touched in 30+ days and known contradiction patterns; appends "Maintenance Flags" to `context/today.md` | `tools/stale-check.sh`, crontab |
| Calendar integration | Optional | Adds today's Google Calendar events to `context/today.md` | `tools/calendar_fetch.py` — requires first-run OAuth setup (see README) |
| Token tracking | Stop hook | Logs context window usage and cost at end of each session | `tools/token-hook.sh` |

### Setup (for a new brain deployment)
1. Run `bash setup.sh` from the repo root — handles path substitution, crontab, and permissions
2. If setup.sh was not used, manually update `BRAIN_DIR_PLACEHOLDER` in `tools/morning-brief.sh` and `tools/stale-check.sh`, and update paths in `.claude/settings.json`
3. Add `@context/today.md` to the brain's CLAUDE.md imports (already done in this template)

### Responding to Maintenance Flags
When `context/today.md` contains a `## Maintenance Flags` section (written by stale-check.sh):
- **STALE (>30d): `path/to/file`** — open the file, update its content to reflect current state
- **CONTRADICTION [`note`]: `path/to/file`** — open the file, find the flagged pattern, apply the correction described in the note
- After fixing all flags, remove the `## Maintenance Flags` section from today.md

### Adding new contradiction patterns to stale-check.sh
Edit `tools/stale-check.sh` and add a line to the `PATTERNS` array:
```bash
"regex_pattern:Human-readable correction note"
```
Use `\|` for OR within the pattern. Test with: `grep -rl --include="*.md" -iE "your_pattern" second-brain/wiki/`

### Extending the automation layer
- Add calendar integration: run `python3 tools/calendar_fetch.py` once to complete OAuth flow
- Add more cron jobs: script writes to `context/`, CLAUDE.md imports it

## Structure
- raw/          — immutable source files (never edit)
- raw/assets/   — downloaded images
- wiki/         — all synthesized knowledge pages
- context/      — personal profile (loaded above via @import)
- decisions/    — append-only decision log
- log.md        — wiki operations log (chronological)
- workflows/    — SOPs for recurring processes
- tools/        — scripts for deterministic execution
- .claude/rules/ — communication and behavior rules

## Wiki page types
- wiki/sources/    — one summary page per ingested source
- wiki/entities/   — people, orgs, products
- wiki/concepts/   — ideas, frameworks, techniques
- wiki/comparisons/ — structured analysis pages
- wiki/meta/       — synthesis, overviews, open questions

## Special files
- wiki/_index.md        — master catalog: link + one-line summary per page
- wiki/_hot.md          — ~500 token cache of most active context (update after every session that changes state)
- wiki/_index-{domain}.md — domain sub-indexes (create as needed when a domain grows beyond 15 pages)
- wiki/_drive-index.md  — lightweight pointer list of all Google Drive deliverables; load only when saving or looking up a document

## Google Drive — Deliverables
Client-facing documents (proposals, reports, leave-behinds, etc.) live in Google Drive. The wiki stores knowledge; Drive stores output documents.

**When saving a deliverable to Drive:**
1. Create the file in Drive under the appropriate folder (IDs in `wiki/_drive-index.md`)
2. Add a row to the Documents table in `wiki/_drive-index.md`
3. Add a `**Drive:**` link line to the relevant wiki source page
4. Do NOT store full document content in the wiki — the Drive link is the pointer

**When looking up a deliverable:**
1. Read `wiki/_drive-index.md` — one read, all pointers
2. Open the Drive link directly

### Editing _hot.md — anchor pattern
For frequently-updated lines in `_hot.md`, use HTML comment anchors as unique identifiers, e.g. `<!-- PROJECT_STATUS -->`. These are invisible when rendered and make Edit calls reliable.

**To update a line:** use Edit with `old_string = "<!-- ANCHOR --> first few words"`. The anchor guarantees uniqueness.

```
old_string: "<!-- PROJECT_STATUS -->- **Project:** Old status"
new_string: "<!-- PROJECT_STATUS -->- **Project:** Updated status"
```

**Never use Write to update _hot.md** unless restructuring the whole file. Edit + anchor is cheaper.

**Anchor index:** (add anchors here as you create them)
| Anchor | Line it protects |
|---|---|
| `<!-- HOT_DATE -->` | Last updated date |

When adding a new frequently-updated line, add an anchor and update this table.

## Retrieval protocol (follow this order for every query)
1. Hot cache first — read wiki/_hot.md (~500 tokens). Resolves most queries.
2. Master index — read wiki/_index.md if hot cache isn't enough.
3. Domain sub-index — open 1-2 relevant _index-{domain}.md files. Never open all sub-indexes at once.
4. Grep fallback — search wiki/**/*.md by keyword if the page isn't indexed.
5. Page limit — NEVER read more than 5 wiki pages per query.

## Operations

### Ingest
Trigger: "ingest [filename]" or "ingest raw/[filename]"
Full SOP: workflows/ingest-source.md

**File type quick reference:**
- `.md` / `.txt` / `.html` / `.pdf` / images — Read tool
- `.pptx` / `.docx` — `tools/extract-office.sh raw/<file>` via Bash (no pip/venv needed)
- Unknown type — check `workflows/ingestion-errors.md` for known fixes

**Self-learning rule:** When any ingestion error is resolved and the user confirms the fix, update `workflows/ingest-source.md` and append a dated entry to `workflows/ingestion-errors.md` before the session ends.

### Query
Trigger: any question about the wiki's knowledge
Steps:
1. Follow retrieval protocol above (5-page hard limit)
2. Synthesize answer with citations to wiki pages
3. If the answer is analysis worth keeping, offer to file it as wiki/comparisons/ or wiki/meta/ page
4. Append to log.md: ## [YYYY-MM-DD] query | [topic]

### Lint
Trigger: "lint the wiki" or "health check"
Steps:
1. Scan wiki/_index.md for orphan pages, stale claims, missing cross-references
2. Flag contradictions between pages
3. Suggest new pages for concepts mentioned but not yet documented
4. Suggest sources for identified knowledge gaps
5. Append to log.md: ## [YYYY-MM-DD] lint | [findings summary]

## Skills
Skills live in .claude/skills/[skill-name]/SKILL.md.
Build a skill when the same workflow appears 3+ times.

## WAT Framework (Workflows · Agents · Tools)
- workflows/ — markdown SOPs for recurring processes. Read before executing.
- tools/     — scripts for deterministic execution. Use before coding ad hoc.
- When something breaks or a better approach emerges:
  1. Fix the tool or approach
  2. Update the workflow to reflect the fix
  3. Log the decision in decisions/log.md
  4. Move forward with a stronger system
- Never overwrite a workflow without asking first unless explicitly told to.

## Rules
- Never edit files in raw/ — they are immutable originals
- Every ingest must update _index.md and log.md — no exceptions
- Keep _hot.md under 500 tokens; trim ruthlessly
- One source = one sources/ page (never combine multiple sources into one summary)
- Cross-link aggressively — every entity and concept page should link to relevant sources
- If a query requires reading more than 5 pages, tell the user and ask them to narrow the question
- Communication rules live in .claude/rules/communication-style.md — follow them

## Maintenance
- priorities.md: update when focus shifts
- goals.md: update at the start of each quarter
- decisions/log.md: append every meaningful decision
- Skills: build when you notice the same request 3+ times
- Workflows: update whenever a better approach is discovered
- stale-check.sh: add new contradiction patterns whenever a recurring staleness pattern is discovered
- Maintenance Flags in today.md: resolve before the next session ends

## Session End — Commit and Push Protocol
At the end of every session where files were changed, commit and push to remote. This is not optional — local-only commits are not backed up.

```bash
git add <specific files>          # never git add -A
git commit -m "..."               # follow existing commit message style
git push origin main              # always push after committing
```

**Commit message format:** `Second brain maintenance YYYY-MM-DD: [2-4 word summary of what changed]`

**What to stage:** all modified context files, wiki pages, raw sources, and new entities/sources created this session. Never stage `.env`, credentials, or `wiki/_staging/` files.

**When the user says "commit" or "push":** do both — commit first if not already done, then push. Never leave commits unpushed at session end.

## Token Management

### Model Routing
Ingestion uses a two-phase pipeline to minimize token cost:
- **Phase 1 (Haiku):** Reads the raw source, produces a structured extraction in wiki/_staging/. Never touches the wiki.
- **Phase 2 (Sonnet):** Reads only the extraction + relevant wiki pages. Integrates into the wiki. Never reads raw sources.

Run ingestion via: `./tools/ingest.sh raw/<filename>`
Batch ingest via: `./tools/ingest-batch.sh raw/<directory>/`

### Session Hygiene Rules
1. **One source per ingest session.** The ingest script handles this automatically by spawning separate claude processes.
2. **Retrieval budget.** During queries, never read more than 5 wiki pages. Follow the retrieval protocol strictly.
3. **No raw reads during queries.** The wiki exists so you don't re-read raw sources. If a query can't be answered from the wiki, flag it as a gap in wiki/meta/gaps.md.
4. **Checkpoint before large operations.** Before lint or multi-page updates, run `./tools/convolife.sh`. If above 60%, checkpoint and /newchat first.
5. **Lazy loading.** Read _hot.md first. Only open additional pages if _hot.md doesn't answer the query.

### Commands
- `convolife` — Check context window usage (or run ./tools/convolife.sh from terminal)
- `checkpoint` — Save 3-5 bullet summary of this session to wiki/meta/checkpoints.md, then safe to /newchat

### Staging Directory
wiki/_staging/ holds temporary extraction files between ingest phases. These are transient — never commit them, never read them during queries. The ingest script cleans them up automatically after integration.
