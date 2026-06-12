# stale-check.ps1 — Windows/PowerShell port of stale-check.sh
# Runs Sundays at 7:05am (after morning-brief). Flags stale pages + contradiction
# patterns, appends a Maintenance section to context\today.md.
# BRAIN_DIR is set by setup.ps1 — do not edit manually.

$BrainDir  = "BRAIN_DIR_PLACEHOLDER"
$WikiDir   = Join-Path $BrainDir "wiki"
$Output    = Join-Path $BrainDir "context\today.md"
$StaleDays = 30
$Issues    = @()

$cutoff = (Get-Date).AddDays(-$StaleDays)
$staleDirs = @(
    (Join-Path $WikiDir "entities"),
    (Join-Path $WikiDir "meta"),
    (Join-Path $BrainDir "context")
) | Where-Object { Test-Path -LiteralPath $_ }

foreach ($d in $staleDirs) {
    Get-ChildItem -LiteralPath $d -Filter *.md -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '_*' -and $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            $rel = $_.FullName.Substring($BrainDir.Length).TrimStart('\', '/')
            $Issues += "STALE (>${StaleDays}d): $rel"
        }
}

# Contradiction patterns: "regex_pattern:Human-readable correction note". Case-insensitive
# (Select-String default). Use | for OR. Add patterns as your knowledge evolves.
$Patterns = @(
    # "old-term:Use new-term instead"
    # "old company name:Company was rebranded - update references"
)

$contraDirs = @(
    (Join-Path $WikiDir "entities"),
    (Join-Path $WikiDir "sources"),
    (Join-Path $WikiDir "meta"),
    (Join-Path $BrainDir "context")
) | Where-Object { Test-Path -LiteralPath $_ }

if ($Patterns.Count -gt 0) {
    $files = Get-ChildItem -LiteralPath $contraDirs -Filter *.md -File -Recurse -ErrorAction SilentlyContinue
    foreach ($entry in $Patterns) {
        $idx = $entry.IndexOf(':')
        $pattern = $entry.Substring(0, $idx)
        $note    = $entry.Substring($idx + 1)
        foreach ($m in (Select-String -Path $files.FullName -Pattern $pattern -List -ErrorAction SilentlyContinue)) {
            if ($m.Path -match '_staging' -or $m.Path -match 'raw[\\/]') { continue }
            $rel = $m.Path.Substring($BrainDir.Length).TrimStart('\', '/')
            $Issues += "CONTRADICTION [$note]: $rel"
        }
    }
}

if ($Issues.Count -gt 0) {
    $date = (Get-Date).ToString("yyyy-MM-dd")
    $block = @("", "---", "## Maintenance Flags ($date)",
               "_Run ``stale-check.ps1`` output. Review and fix before next session._", "")
    foreach ($i in $Issues) { $block += "- $i" }
    Add-Content -LiteralPath $Output -Value ($block -join "`n") -Encoding UTF8
    Write-Output "[stale-check] $($Issues.Count) issue(s) appended to today.md"
} else {
    Write-Output "[stale-check] No issues found."
}
