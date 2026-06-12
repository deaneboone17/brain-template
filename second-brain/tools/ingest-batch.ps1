# ingest-batch.ps1 — Windows/PowerShell port of ingest-batch.sh
# Batch ingest each file in a directory (or a list of files) through the two-phase pipeline.
# Usage:  pwsh -File second-brain\tools\ingest-batch.ps1 raw\some-folder
#    or:  pwsh -File second-brain\tools\ingest-batch.ps1 raw\a.md raw\b.pdf

param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Paths)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Ingest    = Join-Path $ScriptDir "ingest.ps1"
$Count = 0; $Errors = 0

function Invoke-One($file) {
    $script:Count++
    Write-Output ""
    Write-Output "--- Processing $script:Count`: $(Split-Path -Leaf $file) ---"
    & $Ingest $file
    if ($LASTEXITCODE -eq 0) { Write-Output "Done: $(Split-Path -Leaf $file)" }
    else { Write-Output "Failed: $(Split-Path -Leaf $file)"; $script:Errors++ }
    Start-Sleep -Seconds 2   # let sessions fully close between files
}

foreach ($p in $Paths) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        Get-ChildItem -LiteralPath $p -File | ForEach-Object { Invoke-One $_.FullName }
    } elseif (Test-Path -LiteralPath $p -PathType Leaf) {
        Invoke-One $p
    } else {
        Write-Output "Warning: $p not found, skipping."
    }
}

Write-Output ""
Write-Output "==========================================="
Write-Output "  Batch complete: $Count processed, $Errors errors"
Write-Output "==========================================="
