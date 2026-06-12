# token-hook.ps1 — Windows/PowerShell port of token-hook.sh (native, no Python).
# Stop hook: reads the hook JSON on stdin, parses the session transcript, and updates
# ~\.claude\token-stats.json with token usage + cost (session + lifetime).

$ErrorActionPreference = 'SilentlyContinue'
$StateFile = Join-Path $env:USERPROFILE ".claude\token-stats.json"

$raw = [Console]::In.ReadToEnd()
try { $hook = $raw | ConvertFrom-Json } catch { $hook = $null }

# Pricing: claude-sonnet-4-6 per token. Update if you use a different model.
$P_IN = 3.00 / 1e6; $P_OUT = 15.00 / 1e6; $P_CW = 3.75 / 1e6; $P_CR = 0.30 / 1e6
$CTX_MAX = 200000

$sessionId  = if ($hook) { "$($hook.session_id)" } else { "" }
$transcript = if ($hook) { "$($hook.transcript_path)" } else { "" }

if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) {
    $projRoot = Join-Path $env:USERPROFILE ".claude\projects"
    $cand = Get-ChildItem -LiteralPath $projRoot -Filter *.jsonl -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($cand) { $transcript = $cand.FullName }
}
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }

$in = 0; $out = 0; $cw = 0; $cr = 0; $maxCtx = 0
foreach ($line in (Get-Content -LiteralPath $transcript)) {
    if (-not $line.Trim()) { continue }
    try { $obj = $line | ConvertFrom-Json } catch { continue }
    if (-not $sessionId -and $obj.sessionId) { $sessionId = "$($obj.sessionId)" }
    $usage = $obj.usage
    if (-not $usage -and $obj.message) { $usage = $obj.message.usage }
    if (-not $usage) { continue }
    $in  += [int]($usage.input_tokens)
    $out += [int]($usage.output_tokens)
    $cw  += [int]($usage.cache_creation_input_tokens)
    $thisCr = [int]($usage.cache_read_input_tokens)
    $cr  += $thisCr
    if ($thisCr -gt $maxCtx) { $maxCtx = $thisCr }
}

$total = $in + $out + $cw + $cr
$cost  = $in * $P_IN + $out * $P_OUT + $cw * $P_CW + $cr * $P_CR
$pct   = [int]($maxCtx * 100 / $CTX_MAX)

$state = [ordered]@{
    current_session_id = ""; current_session_cost = 0.0; current_context_pct = 0
    current_context_tokens = 0; current_input_tokens = 0; current_output_tokens = 0
    current_total_tokens = 0; lifetime_cost = 0.0; lifetime_sessions = 0; updated_at = ""
}
if (Test-Path -LiteralPath $StateFile) {
    try {
        $saved = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
        foreach ($p in $saved.PSObject.Properties) { $state[$p.Name] = $p.Value }
    } catch { }
}

if ($sessionId -and $sessionId -ne $state.current_session_id) {
    $prev = [double]$state.current_session_cost
    if ($prev -gt 0) {
        $state.lifetime_cost     = [double]$state.lifetime_cost + $prev
        $state.lifetime_sessions = [int]$state.lifetime_sessions + 1
    }
}

$state.current_session_id     = $sessionId
$state.current_session_cost   = [math]::Round($cost, 6)
$state.current_context_pct    = $pct
$state.current_context_tokens = $maxCtx
$state.current_input_tokens   = $in
$state.current_output_tokens  = $out
$state.current_total_tokens   = $total
$state.updated_at             = (Get-Date).ToUniversalTime().ToString("o")

$state | ConvertTo-Json | Set-Content -LiteralPath $StateFile -Encoding UTF8
