# [YOUR NAME]'s Second Brain

This folder is Claude Code's workspace for acting as your executive assistant. Tasks here may include managing schedules, drafting communications, organizing information, tracking projects, and anything else needed to support your day-to-day work.

## Context (auto-loaded every session)

@second-brain/context/me.md
@second-brain/context/work.md
@second-brain/context/priorities.md
@second-brain/wiki/_hot.md
@second-brain/context/today.md

## Second Brain

Full knowledge base lives in `second-brain/`. Retrieval protocol:
1. Hot cache above resolves most queries
2. Read `second-brain/wiki/_index.md` for the full catalog
3. Open specific wiki pages as needed (max 5 per query)
4. Never read files in `second-brain/raw/` — wiki pages exist so you don't have to
