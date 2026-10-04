# t2_restore_parked_watchers_r2.ps1 - round 2.
# Restore every parked (Disabled) git-sync-watch-* scheduled task on this
# machine, mirroring watch.ps1 -RestoreParked (Enable + Start). Runs from the
# goutoujunshi watcher so the user does not have to type anything. ASCII-only.
# Exit codes: 0 ok, 2 some watcher could not be restored.

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..\..')
$repo = (Get-Location).Path
$statusDir = Join-Path $repo 'results\status'
New-Item -ItemType Directory -Force -Path $statusDir | Out-Null
$report = Join-Path $statusDir 'WATCHERS_RESTORED_R2.md'
$lines = New-Object System.Collections.Generic.List[string]

function San([string]$s) {
    if ($null -eq $s) { return '' }
    try { $s = $s -replace '[^\x20-\x7E]','?' } catch { }
    return $s
}
function L([string]$m) { $script:lines.Add($m) | Out-Null; Write-Output $m }
function W([string]$p,[object]$content) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
    Set-Content -LiteralPath $p -Encoding UTF8 -Value $content
}

$selfTask = 'git-sync-watch-' + (Split-Path -Leaf $repo)

L '# Parked watchers restore r2'
L ('time=' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))
L ('host=' + $env:COMPUTERNAME)
L ('self_task=' + $selfTask)
L ''

$tasks = @()
try { $tasks = @(Get-ScheduledTask -TaskName 'git-sync-watch-*' -ErrorAction SilentlyContinue) } catch { }
$disabledBefore = @($tasks | Where-Object { $_.State -eq 'Disabled' })
L ('watchers_total=' + $tasks.Count)
L ('watchers_disabled_before=' + $disabledBefore.Count)
L ''

$restored = 0
$failed = 0
foreach ($t in $tasks) {
    if ($t.TaskName -eq $selfTask) {
        L ('self| ' + $t.TaskName + ' state=' + $t.State + ' (left alone)')
        continue
    }
    L ('task| ' + $t.TaskName + ' state(before)=' + $t.State)
    if ($t.State -eq 'Disabled') {
        $okE = $false
        $okS = $false
        try { Enable-ScheduledTask -TaskName $t.TaskName -ErrorAction Stop | Out-Null; $okE = $true } catch { L ('enable_error| ' + (San $_.Exception.Message)) }
        try { Start-ScheduledTask -TaskName $t.TaskName -ErrorAction Stop; $okS = $true } catch { L ('start_error| ' + (San $_.Exception.Message)) }
        if ($okE) {
            $restored++
            L ('restored| ' + $t.TaskName + ' enabled=' + $okE + ' started=' + $okS)
        } else {
            $failed++
            L ('restore_failed| ' + $t.TaskName)
        }
    } else {
        L ('skip| ' + $t.TaskName + ' already active (' + $t.State + ')')
    }
}
L ''

# settle a moment, then read the final states
Start-Sleep -Seconds 3
$final = @()
try { $final = @(Get-ScheduledTask -TaskName 'git-sync-watch-*' -ErrorAction SilentlyContinue) } catch { }
foreach ($t in $final) { L ('final| ' + $t.TaskName + ' state=' + $t.State) }
$disabledAfter = @($final | Where-Object { $_.State -eq 'Disabled' }).Count
L ''
L ('watchers_restored=' + $restored)
L ('watchers_restore_failed=' + $failed)
L ('watchers_disabled_after=' + $disabledAfter)

$ok = ($failed -eq 0 -and $disabledAfter -eq 0)
L ('WATCHERS_RESTORED_OK=' + $ok)
W $report $lines
if (-not $ok) { exit 2 }
exit 0
