<#
.SYNOPSIS
  AFK driver — unattended e2e-flight Task-queue drain.
  Loops fresh /e2e-flight sessions. Each spawn = fresh context (external /clear).

.DESCRIPTION
  Drives the Task queue at .e2e-engineering/queue.json one Task-step per spawn.
  WARNING: Runs with --dangerously-skip-permissions. All tool calls execute
  without approval. Only reachable post-gate-1 (flight needs a selected queue).

  Sets E2E_DRIVER=1 so /e2e-flight enters worker mode (Step 0 guard) instead of
  re-spawning a driver. Catches four signals on each session's tail:
    <e2e-complete>   -> success, exit 0
    <e2e-stall>      -> human needed, exit 1
    <e2e-task-done>  -> next Task, respawn
    <e2e-checkpoint> -> resume same Task, respawn

.USAGE
  .\afk.ps1                          # claude default, /e2e-flight
  .\afk.ps1 -AI opencode             # opencode preset
  .\afk.ps1 -AI codex                # codex preset
  .\afk.ps1 -Command "custom cmd"    # custom override
  .\afk.ps1 -Skill "/other-skill"    # different skill
  .\afk.ps1 -MaxSessions 50          # raise ceiling
#>
param(
    [ValidateSet("claude", "opencode", "codex")]
    [string]$AI = "claude",
    [string]$Command = "",
    [string]$Skill = "/e2e-flight",
    [int]$MaxSessions = 50,
    # Runaway guard: max consecutive checkpoints on the SAME Task with no task-done
    # between them. A Task that keeps checkpointing without finishing is making no
    # forward progress — stop before it burns the whole session ceiling in tokens.
    [int]$MaxStuckCheckpoints = 6,
    [string]$StateDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# State dir holds queue.json, flight.log, flight.lock, flight-status.md.
if (-not $StateDir) {
    $StateDir = if (Test-Path ".e2e-engineering") { ".e2e-engineering" } else { $PSScriptRoot }
}
$logFile  = Join-Path $StateDir "flight.log"
$lockFile = Join-Path $StateDir "flight.lock"

# Duplicate-driver guard: refuse to start if a live driver already owns the lock.
if (Test-Path $lockFile) {
    $existingPid = (Get-Content $lockFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
        Write-Host "[afk] Driver already running (PID $existingPid). Not starting a second. Watch $logFile." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue   # stale lock
}
$PID | Out-File -FilePath $lockFile -Encoding ascii

$presets = @{
    "claude"   = "claude --print --dangerously-skip-permissions `"$Skill`""
    "opencode" = "opencode -p --dangerously-skip-permissions `"$Skill`""
    "codex"    = "codex exec --dangerously-bypass-approvals-and-sandbox `"$Skill`""
}

$cmd = if ($Command) { $Command } else { $presets[$AI] }
$session = 0
$startTime = Get-Date
$stuckCheckpoints = 0   # consecutive checkpoints with no intervening task-done

# Worker mode for /e2e-flight Step 0 guard. Set once for all child spawns.
$env:E2E_DRIVER = "1"

function Write-Afk([string]$msg, [string]$color = "Cyan") {
    $line = "[afk $(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

try {
    Write-Afk "Starting. AI=$AI MaxSessions=$MaxSessions Skill=$Skill"
    Write-Afk "Command: $cmd" "DarkGray"
    Write-Afk "Console mirrored to $logFile · current state in $(Join-Path $StateDir 'flight-status.md')" "DarkGray"

    while ($session -lt $MaxSessions) {
        $session++
        Write-Afk "Session $session/$MaxSessions" "Green"

        $outputLines = [System.Collections.Generic.List[string]]::new()
        Invoke-Expression $cmd 2>&1 | ForEach-Object {
            Write-Host $_
            Add-Content -Path $logFile -Value ([string]$_) -ErrorAction SilentlyContinue
            $outputLines.Add([string]$_)
        }

        $tail = ($outputLines | Select-Object -Last 30) -join "`n"

        # Order matters: complete/stall are terminal; task-done/checkpoint respawn.
        if ($tail -match '<e2e-complete\s*(?:[^/]*)/>') {
            $elapsed = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
            Write-Afk "COMPLETE — queue drained after $session session(s) [$elapsed]" "Green"
            exit 0
        }

        if ($tail -match '<e2e-stall\s+reason="([^"]*)"') {
            Write-Afk "STALL: $($Matches[1]). Human input required." "Yellow"
            Write-Afk "Resolve then resume: .\.e2e-engineering\afk.ps1"
            exit 1
        }

        if ($tail -match '<e2e-task-done\s+id="([^"]*)"') {
            Write-Afk "Task done: $($Matches[1]). Next Task -> session $($session + 1)..." "Cyan"
            $stuckCheckpoints = 0   # real forward progress — reset the runaway counter
            continue
        }

        if ($tail -match '<e2e-checkpoint\s+handoff="([^"]*)"') {
            $stuckCheckpoints++
            Write-Afk "Checkpoint ($stuckCheckpoints/$MaxStuckCheckpoints). Handoff: $($Matches[1]). Resuming same Task..." "Cyan"
            if ($stuckCheckpoints -ge $MaxStuckCheckpoints) {
                Write-Afk "RUNAWAY: $MaxStuckCheckpoints consecutive checkpoints, no Task completed. Stopping to avoid token burn." "Red"
                Write-Afk "Inspect $(Join-Path $StateDir 'flight-status.md') + handoff, then resume manually." "Red"
                exit 4
            }
            continue
        }

        Write-Afk "No signal detected in session $session. Review output." "Red"
        $outputLines | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" }
        exit 2
    }

    Write-Afk "Safety ceiling reached ($MaxSessions sessions)." "Red"
    exit 3
}
finally {
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
}
