# statusbar.ps1 — Windows/PowerShell port of statusbar.sh (native, no Python).
# Reads ~\.claude\token-stats.json and prints one status line. Registered as the
# Claude Code statusCommand in .claude\settings.json.

$StateFile = Join-Path $env:USERPROFILE ".claude\token-stats.json"
if (-not (Test-Path -LiteralPath $StateFile)) {
    Write-Output "ctx --  |  session --  |  lifetime --"; exit 0
}
try { $s = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json }
catch { Write-Output "ctx --  |  session --  |  lifetime --"; exit 0 }

$ctx      = [int]   ($s.current_context_pct)
$sessCost = [double]($s.current_session_cost)
$lifetime = [double]($s.lifetime_cost) + $sessCost
$sessions = [int]   ($s.lifetime_sessions) + 1
$outTok   = [int]   ($s.current_output_tokens)

$filled = [math]::Floor($ctx / 10)
if ($filled -gt 10) { $filled = 10 }
$bar = ('#' * $filled) + ('-' * (10 - $filled))
$warn = if ($ctx -ge 80) { ' !' } elseif ($ctx -ge 60) { ' ~' } else { '' }

function Format-K($n) { if ($n -ge 1000) { ('{0:N1}k' -f ($n / 1000)) } else { "$n" } }

$sessStr = '{0:N4}' -f $sessCost
$lifeStr = '{0:N2}' -f $lifetime
Write-Output ("ctx [$bar] $ctx%$warn  |  sess `$$sessStr ($(Format-K $outTok) out)  |  lifetime `$$lifeStr / $sessions sessions")
