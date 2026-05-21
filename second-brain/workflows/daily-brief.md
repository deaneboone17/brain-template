# Daily Brief

**Trigger:** "daily brief", "what's my day look like", or start of any work session
**Goal:** One focused output: what to work on today, ranked by priority. No fluff.
**Inputs required:** None — pulls from context files. Override with "focus on [project]" if needed.

## Steps
1. Read context/today.md — check for hard deadlines and this-week task table (written by morning-brief.sh at 7am)
2. Read context/priorities.md — identify the top unblocked priority
3. Read wiki/_hot.md — check for any active context that changes today's focus
4. Generate daily to-do list:
   - 1 Most Important Task (MIT) — the single thing that moves the needle most
   - 2-3 supporting tasks that ladder up to the MIT or a secondary priority
   - 1 quick win (under 30 min) if relevant
5. Flag any builder-mode risk: if recent sessions have circled the same tasks without shipping, say so
6. Output as a clean bullet list. No preamble.

## Output format
```
MIT: [one task]

Supporting:
- [task]
- [task]

Quick win: [task]

Check: [any flag or blocker worth naming]
```

## Tools used
None — reads context files only.

## Edge cases
- **No clear MIT:** Ask "What would make today a win?" rather than guessing.
- **Multiple fires:** Rank by income impact first, then momentum, then everything else.

**Last updated:** 2026-05-20
