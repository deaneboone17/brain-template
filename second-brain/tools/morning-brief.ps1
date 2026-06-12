# morning-brief.ps1 — Windows/PowerShell port of morning-brief.sh
# Runs at 7am daily (Task Scheduler). Writes context\today.md with date, calendar,
# upcoming deadlines, and this-week tasks.
# BRAIN_DIR is set by setup.ps1 — do not edit manually.

$BrainDir   = "BRAIN_DIR_PLACEHOLDER"
$Output     = Join-Path $BrainDir "context\today.md"
$Priorities = Join-Path $BrainDir "context\priorities.md"

# Section headers parsed from priorities.md. If you rename these sections, update here.
$DeadlinesHeader = "## Hard Deadlines"
$ThisWeekHeader  = "## This Week"

$Today     = (Get-Date).ToString("dddd, MMMM dd, yyyy")
$Generated = (Get-Date).ToString("yyyy-MM-dd hh:mm tt")

function Get-Section {
    param([string]$Path, [string]$Header, [switch]$TableRows)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $found = $false; $out = @()
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if (-not $found) {
            if ($line -match [regex]::Escape($Header)) { $found = $true }
            continue
        }
        if ($line -match '^##\s') { break }           # next section ends it
        if ($TableRows) { if ($line -match '^\|') { $out += $line } }
        else            { if ($line -match '^- ')  { $out += $line } }
    }
    return ($out -join "`n")
}

$Deadlines = Get-Section -Path $Priorities -Header $DeadlinesHeader
$ThisWeek  = (Get-Section -Path $Priorities -Header $ThisWeekHeader -TableRows) -split "`n" |
    Where-Object { $_ -notmatch '~~' -and $_ -notmatch 'Status' -and $_ -notmatch '^\|-' }
$ThisWeek  = ($ThisWeek -join "`n")

# Calendar (optional — fails gracefully if Python / calendar_fetch not set up)
$Calendar  = "(Calendar unavailable - see README for setup)"
$calScript = Join-Path $BrainDir "tools\calendar_fetch.py"
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if ($py -and (Test-Path -LiteralPath $calScript)) {
    try {
        $c = & $py.Source $calScript 2>$null
        if ($LASTEXITCODE -eq 0 -and $c) { $Calendar = ($c -join "`n") }
    } catch { }
}

$content = @"
# today.md
_Auto-generated: $Generated. Do not edit - overwritten each morning._

## Today
**$Today**

## Calendar
$Calendar

## Hard Deadlines
$Deadlines

## This Week
$ThisWeek
"@

Set-Content -LiteralPath $Output -Value $content -Encoding UTF8
Write-Output "[morning-brief] context/today.md updated at $Generated"
