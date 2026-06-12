# Running brain-template on Windows (PowerShell)

The template ships a full Windows layer alongside the Linux/Mac one. Same brain, same Claude Code
behavior — the platform-specific bits (the setup script, the automation hooks, the daily/weekly
jobs, and the tool scripts) have PowerShell equivalents, and **Task Scheduler replaces cron**.

You do **not** need WSL, Git Bash, `jq`, `unzip`, or `cron`. Everything runs in native PowerShell.

## Prerequisites
| Dependency | Notes |
|---|---|
| [Claude Code](https://github.com/anthropics/claude-code) | `npm install -g @anthropic/claude-code`, authenticated |
| Git | for version control / backup |
| PowerShell | **5.1 (built into Windows)** or **PowerShell 7+** (`winget install Microsoft.PowerShell`) |
| Python 3 (optional) | only for the Google Calendar integration; token tracking + status bar are native PowerShell |

## Setup
```powershell
git clone https://github.com/YOUR_USERNAME/brain-template.git my-brain
cd my-brain
powershell -ExecutionPolicy Bypass -File setup.ps1     # or: pwsh -ExecutionPolicy Bypass -File setup.ps1
```
`setup.ps1` does the Windows equivalent of `setup.sh`:
1. Substitutes your absolute path into `tools\morning-brief.ps1` + `tools\stale-check.ps1`.
2. Writes `.claude\settings.json` from `.claude\settings.windows.json` (PowerShell hooks: timestamp
   injection, token tracking, status bar).
3. Registers two **scheduled tasks**: `BrainMorningBrief` (daily 7:00am) and `BrainStaleCheck`
   (Sundays 7:05am).
4. Creates an initial `second-brain\context\today.md`.

Then populate your context files and start:
```powershell
claude
```

## Execution policy
The scheduled tasks and hooks invoke PowerShell with `-ExecutionPolicy Bypass`, so they run without
changing your machine policy. To run the tools **manually** without `-ExecutionPolicy Bypass` each
time, allow local scripts once:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## The tools (PowerShell)
| Linux | Windows | Run it |
|---|---|---|
| `morning-brief.sh` | `morning-brief.ps1` | Task Scheduler (`BrainMorningBrief`) |
| `stale-check.sh` | `stale-check.ps1` | Task Scheduler (`BrainStaleCheck`) |
| `token-hook.sh` | `token-hook.ps1` | Stop hook (automatic) |
| `statusbar.sh` | `statusbar.ps1` | status bar (automatic) |
| `convolife.sh` | `convolife.ps1` | `pwsh -File second-brain\tools\convolife.ps1` |
| `ingest.sh` | `ingest.ps1` | `pwsh -File second-brain\tools\ingest.ps1 raw\file.pdf` |
| `ingest-batch.sh` | `ingest-batch.ps1` | `pwsh -File second-brain\tools\ingest-batch.ps1 raw\folder` |
| `extract-office.sh` | `extract-office.ps1` | `pwsh -File second-brain\tools\extract-office.ps1 raw\deck.pptx` |
| `calendar_fetch.py` | (same — cross-platform Python) | optional |

## Managing the scheduled tasks
```powershell
Get-ScheduledTask -TaskName Brain*                       # confirm both registered
Start-ScheduledTask -TaskName BrainMorningBrief          # run the brief now (test)
Get-Content second-brain\context\today.md                # verify output
Unregister-ScheduledTask -TaskName BrainMorningBrief,BrainStaleCheck -Confirm:$false   # remove
```
Tasks run under your user account while you're logged in. If you want them to run when logged out,
re-create them in Task Scheduler with "Run whether user is logged on or not" (requires storing
credentials) — not enabled by default to avoid prompting for your password.

## Notes / differences from Linux
- **Money/cost + token tracking** is computed natively in PowerShell (no Python needed).
- **Office extraction** uses the .NET zip reader (`System.IO.Compression`) instead of `unzip`.
- **`convolife.ps1`** locates Claude Code's session folder by sanitizing the project path; if Windows
  sanitizes differently than expected it falls back to the most recent session across all projects.
- **Calendar** still uses `calendar_fetch.py` (cross-platform); follow the README Calendar steps and
  run it once to authorize. `pip install google-auth google-auth-oauthlib google-api-python-client`.
- Both layers can coexist in one clone — running `setup.ps1` only overwrites `.claude\settings.json`
  with the Windows variant; the `.sh` tools are left untouched for Linux/Mac use.
