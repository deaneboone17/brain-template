# setup.ps1 — one-time Windows setup for brain-template (PowerShell equivalent of setup.sh)
# Run from the repo root:
#   pwsh -ExecutionPolicy Bypass -File setup.ps1      (PowerShell 7+)
#   powershell -ExecutionPolicy Bypass -File setup.ps1 (Windows PowerShell 5.1)

$ErrorActionPreference = 'Stop'

$RepoDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$BrainDir = Join-Path $RepoDir "second-brain"
$RepoFwd  = $RepoDir -replace '\\', '/'   # forward-slash form for JSON (avoids escaping)

Write-Host ""
Write-Host "==========================================="
Write-Host "  Brain Template Setup (Windows)"
Write-Host "==========================================="
Write-Host "Repo root:  $RepoDir"
Write-Host "Brain dir:  $BrainDir"
Write-Host ""

# ── 1. Substitute BRAIN_DIR placeholder into the PowerShell tools ──────────────
Write-Host "[1/4] Updating BRAIN_DIR paths in PowerShell tools..."
foreach ($t in @('morning-brief.ps1', 'stale-check.ps1')) {
    $p = Join-Path $BrainDir "tools\$t"
    (Get-Content -LiteralPath $p -Raw).Replace('BRAIN_DIR_PLACEHOLDER', $BrainDir) |
        Set-Content -LiteralPath $p -Encoding UTF8
}
Write-Host "    Done."

# ── 2. Write the Windows .claude\settings.json from the template ───────────────
Write-Host "[2/4] Writing .claude\settings.json (PowerShell hooks)..."
$tmpl = Join-Path $RepoDir ".claude\settings.windows.json"
$dest = Join-Path $RepoDir ".claude\settings.json"
(Get-Content -LiteralPath $tmpl -Raw).Replace('REPO_DIR_PLACEHOLDER', $RepoFwd) |
    Set-Content -LiteralPath $dest -Encoding UTF8
Write-Host "    Done. (Overwrote the bash settings.json with the Windows variant.)"

# ── 3. Register scheduled tasks (Task Scheduler replaces cron) ─────────────────
Write-Host "[3/4] Registering scheduled tasks..."
$psExe = (Get-Command powershell -ErrorAction SilentlyContinue).Source
if (-not $psExe) { $psExe = (Get-Command pwsh).Source }

$mbAction  = New-ScheduledTaskAction  -Execute $psExe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$BrainDir\tools\morning-brief.ps1`""
$mbTrigger = New-ScheduledTaskTrigger -Daily -At "7:00AM"
Register-ScheduledTask -TaskName "BrainMorningBrief" -Action $mbAction -Trigger $mbTrigger `
    -Description "Brain daily brief (context\today.md)" -Force | Out-Null

$scAction  = New-ScheduledTaskAction  -Execute $psExe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$BrainDir\tools\stale-check.ps1`""
$scTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "7:05AM"
Register-ScheduledTask -TaskName "BrainStaleCheck" -Action $scAction -Trigger $scTrigger `
    -Description "Brain weekly staleness + contradiction check" -Force | Out-Null
Write-Host "    BrainMorningBrief: daily 7:00am"
Write-Host "    BrainStaleCheck:   Sundays 7:05am"

# ── 4. Create initial today.md ─────────────────────────────────────────────────
Write-Host "[4/4] Creating initial today.md..."
$today = (Get-Date).ToString("dddd, MMMM dd, yyyy")
$gen   = (Get-Date).ToString("yyyy-MM-dd hh:mm tt")
$todayContent = @"
# today.md
_Auto-generated: $gen. Overwritten each morning by morning-brief.ps1._

## Today
**$today**

## Calendar
(Calendar unavailable - see README for Google Calendar setup)

## Hard Deadlines
(Populated from context/priorities.md once you fill it in)

## This Week
(Populated from context/priorities.md once you fill it in)
"@
Set-Content -LiteralPath (Join-Path $BrainDir "context\today.md") -Value $todayContent -Encoding UTF8
Write-Host "    Done."

Write-Host ""
Write-Host "==========================================="
Write-Host "  Setup complete."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Fill in second-brain\context\ files (or run the onboarding prompt)"
Write-Host "  2. Run 'claude' in this directory to start"
Write-Host "  3. Optional: set up Google Calendar (see README)"
Write-Host ""
Write-Host "  Note: scheduled tasks run under your user account while you're logged in."
Write-Host "  To verify: Get-ScheduledTask -TaskName Brain*"
Write-Host "==========================================="
Write-Host ""
