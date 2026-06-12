# convolife.ps1 — Windows/PowerShell port of convolife.sh
# Check context window usage for the current project.
# Usage:  pwsh -File second-brain\tools\convolife.ps1   (run from the repo root)

$ProjectPath = (Get-Location).Path
# Claude Code stores sessions under a sanitized project path (separators -> hyphens).
$Safe = ($ProjectPath -replace '[\\/:]', '-').TrimStart('-')
$SessionDir = Join-Path $env:USERPROFILE ".claude\projects\$Safe"

$latest = $null
if (Test-Path -LiteralPath $SessionDir) {
    $latest = Get-ChildItem -LiteralPath $SessionDir -Filter *.jsonl -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if (-not $latest) {
    # Fallback: newest session across all projects (Windows path sanitization can vary).
    $projRoot = Join-Path $env:USERPROFILE ".claude\projects"
    if (Test-Path -LiteralPath $projRoot) {
        $latest = Get-ChildItem -LiteralPath $projRoot -Filter *.jsonl -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
}
if (-not $latest) { Write-Output "No session data found for this project."; exit 0 }

# Last cache_read_input_tokens value in the transcript = current context size.
$tokens = $null
Select-String -LiteralPath $latest.FullName -Pattern '"cache_read_input_tokens":(\d+)' -AllMatches |
    ForEach-Object { $_.Matches } |
    ForEach-Object { $tokens = [int]$_.Groups[1].Value }

if (-not $tokens) { Write-Output "Could not determine token usage. Session may be fresh."; exit 0 }

$max = 200000
$pct = [math]::Floor($tokens * 100 / $max)
$remaining = [math]::Floor(($max - $tokens) / 1000)
Write-Output "Context window: $pct% used (~${remaining}k tokens remaining)"
if     ($pct -gt 80) { Write-Output "WARNING: Context is getting full. Consider checkpoint + /newchat." }
elseif ($pct -gt 60) { Write-Output "Moderate usage. Safe for small operations. Avoid large file reads." }
else                 { Write-Output "Plenty of room." }
