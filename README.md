# brain-template

A Claude Code-powered personal second brain and executive assistant. Drop this repo on any machine, run the setup script, fill in your context files, and Claude Code becomes a persistent AI assistant that knows who you are, what you're working on, and what matters most — across every session.

## What it does

- **Persistent memory** across sessions via structured context files
- **Daily briefing** auto-generated every morning at 7am from your priorities and calendar
- **Knowledge ingestion** — drop any file into `raw/` and Claude extracts, summarizes, and indexes it
- **Self-maintenance** — weekly staleness check catches outdated pages and contradictions automatically
- **Token tracking** — status bar shows context window %, session cost, and lifetime spend
- **Obsidian-compatible** — the entire `second-brain/` directory opens as an Obsidian vault

---

## Dependencies

### Required
| Dependency | Install | Notes |
|---|---|---|
| [Claude Code](https://github.com/anthropics/claude-code) | `npm install -g @anthropic/claude-code` | The engine. Must be authenticated. |
| Git | Pre-installed on most systems | For version control and backup |
| Bash **or** PowerShell | Bash pre-installed on Linux/Mac; **PowerShell** built into Windows | Linux/Mac use the `.sh` tools; Windows uses the `.ps1` tools (see [docs/WINDOWS.md](docs/WINDOWS.md)) |
| Python 3 | `sudo apt install python3` or pre-installed | Linux: token tracking (statusbar, token-hook). **Windows: not required** — those are native PowerShell; Python only for optional Calendar |
| jq | `sudo apt install jq` | Linux only (convolife.sh, statusbar.sh). **Not needed on Windows** |
| unzip | `sudo apt install unzip` | Linux only (extract-office.sh). **Not needed on Windows** (.NET zip reader) |
| cron **or** Task Scheduler | cron on Linux/Mac; Task Scheduler on Windows | For daily brief + staleness check |

### Optional
| Dependency | Install | Notes |
|---|---|---|
| [Obsidian](https://obsidian.md) | Download from obsidian.md | Best way to browse and search the wiki visually |
| Google Calendar API | See [Calendar Setup](#optional-google-calendar) below | Adds live calendar to daily brief |
| Google Cloud SDK (`gcloud`) | [Install guide](https://cloud.google.com/sdk/docs/install) | Only needed for Calendar API setup |

### Python packages (optional — only for Calendar integration)
```bash
pip install google-auth google-auth-oauthlib google-api-python-client
```

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/brain-template.git my-brain
cd my-brain
```

Or use this as a GitHub template: click **Use this template** at the top of the repo.

### 2. Run the setup script

**Linux / Mac:**
```bash
bash setup.sh
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

This will:
- Substitute your absolute path into the tool scripts
- (Linux/Mac) set permissions; (Windows) write the PowerShell `.claude\settings.json`
- Add morning-brief (7am daily) and stale-check (7:05am Sundays) — to **cron** on Linux/Mac, or
  **Task Scheduler** on Windows (`BrainMorningBrief` / `BrainStaleCheck`)
- Create an initial `context/today.md`

> **Windows users:** the full Windows layer (PowerShell ports of every tool, Task Scheduler jobs,
> native token tracking — no WSL/jq/unzip/cron needed) is documented in **[docs/WINDOWS.md](docs/WINDOWS.md)**.

### 3. Connect to GitHub (recommended)

```bash
git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

Your second brain is backed up on every commit.

### 4. Populate your context files

**Option A — Onboarding prompt (recommended):** Open Claude Code in this directory and paste the onboarding prompt below. Claude will interview you and write all context files.

**Option B — Manual:** Edit the template files in `second-brain/context/` directly.

### 5. Start Claude Code

```bash
claude
```

Claude will load your context files automatically on every session.

---

## Onboarding Prompt

Paste this into Claude Code after setup to have Claude populate all your context files through a guided interview:

```
I'm setting up my second brain for the first time. Help me populate the context files by 
interviewing me section by section. After I answer each section, write the corresponding 
file immediately before moving to the next.

Work through these files in order:
1. second-brain/context/me.md — Ask me about: my name, location, timezone, contact info, 
   what I do professionally, my current roles and tracks, my #1 priority in life, how I 
   position myself professionally, my family situation, and any standing requirements I 
   have (e.g., legal, financial, or personal rules I always follow).

2. second-brain/context/work.md — Ask me about: my primary ventures or employer, my role 
   at each, key contacts, the tools I use daily, and how I access this machine remotely 
   (if applicable).

3. second-brain/context/priorities.md — Ask me about: my top 3-5 priorities right now 
   (ranked), what I need to accomplish this week, all active projects and their status, 
   and any hard deadlines coming up.

4. second-brain/context/goals.md — Ask me about: my goals for this quarter (must-achieve, 
   should-achieve, nice-to-have) and my longer-term direction (1-3 years out).

After all four files are written:
5. Update second-brain/wiki/_hot.md with a brief version of my identity and top 2-3 
   active situations drawn from what I told you.
6. Update CLAUDE.md at the repo root to replace [YOUR NAME] with my actual name.
7. Commit all files with message: "Second brain initialized YYYY-MM-DD: onboarding complete"

Ask one section at a time. Don't move to the next until I confirm the written file looks right.
```

---

## Daily Use

### Start a session
```bash
cd my-brain
claude
```

Claude loads your context automatically. Ask it anything:
- "What should I work on today?"
- "Daily brief"
- "What's the status of [project]?"
- "Ingest raw/meeting-notes.md"

### Add knowledge
Drop any file into `second-brain/raw/` then:
```bash
# From the terminal
./second-brain/tools/ingest.sh second-brain/raw/your-file.pdf

# Or in Claude Code
ingest raw/your-file.pdf
```

Supported formats: `.md`, `.txt`, `.html`, `.pdf`, `.pptx`, `.docx`, images

### Check context usage
```bash
./second-brain/tools/convolife.sh
```

Or just look at the status bar in Claude Code (bottom of screen).

---

## Directory Structure

```
my-brain/
├── CLAUDE.md                    # Top-level config — tells Claude its role
├── setup.sh                     # One-time setup script
├── .gitignore
├── .claude/
│   └── settings.json            # Hooks: timestamp injection, token tracking, status bar
└── second-brain/
    ├── CLAUDE.md                # Schema, protocols, retrieval rules
    ├── CLAUDE.local.md          # Local overrides (git-ignored)
    ├── context/                 # Personal profile — auto-loaded every session
    │   ├── me.md                # Identity, roles, standing requirements
    │   ├── work.md              # Ventures, tools, daily workflow
    │   ├── priorities.md        # Ranked priorities, active projects, deadlines
    │   ├── goals.md             # Quarterly + long-term goals
    │   └── today.md             # Auto-generated daily by morning-brief.sh
    ├── wiki/                    # All synthesized knowledge
    │   ├── _index.md            # Master catalog (one line per page)
    │   ├── _hot.md              # ~500 token active context cache
    │   ├── _drive-index.md      # Google Drive deliverables pointer list
    │   ├── entities/            # People, organizations, products
    │   ├── sources/             # Ingested source summaries
    │   ├── concepts/            # Ideas, frameworks, techniques
    │   ├── meta/                # Synthesis, overviews, open questions
    │   └── comparisons/         # Structured analysis pages
    ├── raw/                     # Drop files here to ingest (never edit)
    ├── decisions/
    │   └── log.md               # Append-only decision log
    ├── log.md                   # Wiki operations log
    ├── workflows/               # SOPs for recurring processes
    │   ├── ingest-source.md
    │   ├── ingestion-errors.md
    │   └── daily-brief.md
    ├── tools/                   # Automation scripts
    │   ├── morning-brief.sh     # Daily context/today.md generator
    │   ├── stale-check.sh       # Weekly staleness + contradiction detector
    │   ├── ingest.sh            # Two-phase ingestion (Haiku + Sonnet)
    │   ├── ingest-batch.sh      # Batch ingest a directory
    │   ├── extract-office.sh    # PPTX/DOCX text extraction (no dependencies)
    │   ├── token-hook.sh        # Session cost tracker (Stop hook)
    │   ├── statusbar.sh         # Claude Code status bar display
    │   ├── convolife.sh         # Context window usage checker
    │   └── calendar_fetch.py    # Google Calendar integration (optional)
    └── .claude/
        └── rules/
            └── communication-style.md
```

---

## Optional: Google Calendar

To add live calendar events to your daily brief:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project (or use an existing one)
3. Enable the Google Calendar API
4. Create OAuth 2.0 credentials (Desktop app type)
5. Download `credentials.json` and place it in `second-brain/tools/credentials.json`
6. Run the script once to authenticate:
   ```bash
   python3 second-brain/tools/calendar_fetch.py
   ```
   A browser window will open for authorization. After completing it, a `token.json` is saved automatically. Subsequent runs (including the 7am cron) will use the saved token.

`credentials.json` and `token.json` are in `.gitignore` — they will never be committed.

---

## Optional: Obsidian

The entire `second-brain/` directory is a valid Obsidian vault. To open it:

1. Install [Obsidian](https://obsidian.md)
2. Open Obsidian → "Open folder as vault"
3. Select the `second-brain/` directory

Recommended plugins:
- **Dataview** — query your wiki as a database
- **Graph view** — visualize connections between pages
- **Daily Notes** — pair with `context/today.md`

The `[[wiki-links]]` format used throughout is native Obsidian syntax.

---

## Maintenance

### Staleness check (automatic)
Every Sunday at 7:05am, `stale-check.sh` scans for:
- Wiki pages not updated in 30+ days
- Contradiction patterns you've defined

Findings appear as a `## Maintenance Flags` section in `context/today.md`. Resolve them before the next session ends.

### Add a contradiction pattern
When you notice the same outdated information appearing repeatedly, add it to `second-brain/tools/stale-check.sh`:

```bash
PATTERNS=(
    "old-term:Use new-term instead"
    "former company name:Company was rebranded — update references"
)
```

### Session end
At the end of every working session, commit and push:
```bash
git add second-brain/context/ second-brain/wiki/
git commit -m "Second brain maintenance YYYY-MM-DD: [what changed]"
git push origin main
```

---

## Frequently Asked Questions

**Q: How do I use this on multiple machines?**
Clone the repo on each machine and run `setup.sh`. The crontab must be set up independently on each machine. Context files sync via git.

**Q: Can multiple people share one brain?**
Yes, but it requires hosting. Each person needs Claude Code access and the repo cloned locally. The easiest path: private GitHub repo + each person clones + both run setup.sh. For a shared "team brain" with a single always-on host, you'd need internet access + auth (out of scope for this template).

**Q: How do I add a new type of automation?**
Write a script that outputs to a file in `second-brain/context/`. Add a cron entry. Add `@second-brain/context/your-file.md` to `CLAUDE.md`. That's it.

**Q: What does a session cost?**
The status bar at the bottom of Claude Code shows real-time session cost. Typical sessions run $0.05–$0.50 depending on how many files are read. The two-phase ingest pipeline (Haiku for extraction, Sonnet for integration) minimizes cost on ingestion.

**Q: The morning brief shows "(Calendar unavailable)" — how do I fix it?**
Follow the [Google Calendar setup](#optional-google-calendar) steps above.

---

## Credits

Built and maintained by [your name]. Template extracted from a production second brain running on Claude Code + Ubuntu + Tailscale.
