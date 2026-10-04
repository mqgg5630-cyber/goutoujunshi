# t3_push_love_letter_skill_r3.ps1 - round 3.
# Verify the love-letter/confession distilled skill assets, copy the list to
# Desktop, and refresh the Gemini Gem folder in Google Drive by reusing the
# existing rclone push task. ASCII-only; do not print secrets.

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..\..')
$repo = (Get-Location).Path
$outDir = Join-Path $repo 'results\cloud_interop'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$report = Join-Path $outDir 'GEM_GDRIVE_PUSH_R3.md'
$lines = New-Object System.Collections.Generic.List[string]

function San([string]$s) {
    if ($null -eq $s) { return '' }
    try { $s = $s -replace 'ya29\.[A-Za-z0-9_\.-]+','[REDACTED-OAUTH]' } catch { }
    try { $s = $s -replace '1//[A-Za-z0-9_\.-]+','[REDACTED-OAUTH]' } catch { }
    try { $s = $s -replace '[A-Za-z0-9+/_=-]{28,}','[REDACTED]' } catch { }
    try { $s = $s -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}','[REDACTED-GUID]' } catch { }
    try { $s = $s -replace '[^\x20-\x7E]','?' } catch { }
    return $s
}
function L([string]$m) { $script:lines.Add($m) | Out-Null; Write-Output $m }
function W([string]$p,[object]$content) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
    Set-Content -LiteralPath $p -Encoding UTF8 -Value $content
}
function Run-Capped([string]$Name,[scriptblock]$Block,[int]$TimeoutSec) {
    $job = Start-Job -ScriptBlock $Block
    if (-not (Wait-Job $job -Timeout $TimeoutSec)) {
        Stop-Job $job -Force -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        return @{ ok=$false; text='TIMEOUT'; code=-1; name=$Name }
    }
    $txt = (Receive-Job $job 2>&1 | Out-String).Trim()
    $state = [string]$job.State
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    $code = -1
    if ($txt -match '===EXITCODE:(-?\d+)') { $code = [int]$Matches[1] }
    $txt = ($txt -replace '===EXITCODE:-?\d+\s*','').Trim()
    return @{ ok=($state -eq 'Completed'); text=$txt; code=$code; name=$Name }
}

L '# Love-letter confession skill refresh r3'
L ('time=' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))
L ('host=' + $env:COMPUTERNAME)
L ('repo=' + (San $repo))
L ''

$list = Join-Path $repo 'documentation\love-letter-confession-skill-scan.md'
$skill = Join-Path $repo 'skills\love-letter-confession\SKILL.md'
$rootSkill = Join-Path $repo 'SKILL.md'
$gemDir = Join-Path $repo 'deliverable\gem'
$t1 = Join-Path $repo 'code\tasks\t1_gdrive_push_gem_r1.ps1'

$listOk = (Test-Path -LiteralPath $list)
$skillOk = (Test-Path -LiteralPath $skill)
$rootOk = $false
try {
    if (Test-Path -LiteralPath $rootSkill) {
        $rt = Get-Content -LiteralPath $rootSkill -Raw -Encoding UTF8
        $rootOk = ($rt -match 'love-letter-confession') -or ($rt -match 'references/practical/')
    }
} catch { }
$gemOk = (Test-Path -LiteralPath $gemDir)
L ('list_ok=' + $listOk)
L ('standalone_skill_ok=' + $skillOk)
L ('root_skill_route_hint_ok=' + $rootOk)
L ('gem_dir_ok=' + $gemOk)

# Copy the scan and standalone skill to Desktop with ASCII names for easy access.
$desktop = [Environment]::GetFolderPath('Desktop')
if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
New-Item -ItemType Directory -Force -Path $desktop | Out-Null
$deskList = Join-Path $desktop 'love-letter-confession-skill-list.md'
$deskSkill = Join-Path $desktop 'love-letter-confession-SKILL.md'
try { if ($listOk) { Copy-Item -LiteralPath $list -Destination $deskList -Force } } catch { L ('copy_list_error=' + (San $_.Exception.Message)) }
try { if ($skillOk) { Copy-Item -LiteralPath $skill -Destination $deskSkill -Force } } catch { L ('copy_skill_error=' + (San $_.Exception.Message)) }
L ('desktop_list=' + (San $deskList) + ' exists=' + (Test-Path -LiteralPath $deskList))
L ('desktop_skill=' + (San $deskSkill) + ' exists=' + (Test-Path -LiteralPath $deskSkill))

# Refresh the Google Drive Gem package using the existing proven rclone task.
$pushOk = $false
if (Test-Path -LiteralPath $t1) {
    $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $push = Run-Capped 'gdrive_push_reuse_r1' {
        & $using:psExe -NoProfile -ExecutionPolicy Bypass -File $using:t1 2>&1 | Out-String
        Write-Output ('===EXITCODE:' + $LASTEXITCODE)
    } 1800
    L ('push_exit=' + $push.code)
    foreach ($ln in (($push.text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 40)) {
        L ('push| ' + (San $ln))
    }
    $r1 = Join-Path $outDir 'GEM_GDRIVE_PUSH_R1.md'
    if (Test-Path -LiteralPath $r1) {
        try { $pushOk = ((Get-Content -LiteralPath $r1 -Raw -Encoding UTF8) -match 'GDRIVE_GEM_PUSH_OK=True') } catch { }
    }
} else {
    L 'r1_push_task_missing=True'
}
L ('GDRIVE_GEM_PUSH_OK=' + $pushOk)

$ok = ($listOk -and $skillOk -and $gemOk -and $pushOk)
L ('LOVE_LETTER_SKILL_READY=' + $ok)
W $report $lines
if (-not $ok) { exit 2 }
exit 0
