# t4_push_love_letter_gem_r4.ps1 - round 4.
# Push the standalone love-letter/confession Gemini Gem library to Google Drive.
# Remote: gdrive_jzthjyz. Folder: Arena/Gem/love-letter-confession.
# ASCII-only. Do not print secrets.

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..\..')
$repo = (Get-Location).Path
$gemDir = Join-Path $repo 'deliverable\gem-love-letter'
$cloudDir = Join-Path $repo 'results\cloud_interop'
New-Item -ItemType Directory -Force -Path $cloudDir | Out-Null
$report = Join-Path $cloudDir 'LOVE_LETTER_GEM_GDRIVE_PUSH_R4.md'
$lines = New-Object System.Collections.Generic.List[string]

$RemoteName = 'gdrive_jzthjyz'
$DriveDir = 'Arena/Gem/love-letter-confession'
$remoteWithColon = $RemoteName + ':'

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
function Get-RcloneExe {
    $cmd = Get-Command rclone -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd -and $cmd.Source) { return [string]$cmd.Source }
    $local = Join-Path $env:LOCALAPPDATA 'Programs\rclone\rclone.exe'
    if (Test-Path -LiteralPath $local) { return $local }
    return ''
}

L '# Love-letter Gemini Gem library -> Google Drive push r4'
L ('time=' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))
L ('host=' + $env:COMPUTERNAME)
L ('remote=' + $remoteWithColon)
L ('drive_dir=' + $DriveDir)
L ''

if (-not (Test-Path -LiteralPath $gemDir)) {
    L 'gem_dir_missing=True'
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 5
}
$mdFiles = @(Get-ChildItem -LiteralPath $gemDir -Filter '*.md' | Sort-Object Name)
$txtDir = Join-Path $gemDir 'txt'
$txtFiles = @()
if (Test-Path -LiteralPath $txtDir) { $txtFiles = @(Get-ChildItem -LiteralPath $txtDir -Filter '*.txt' | Sort-Object Name) }
L ('gem_md_files_local=' + $mdFiles.Count)
L ('gem_txt_files_local=' + $txtFiles.Count)
L 'gem_expected_md=12 gem_expected_txt=10'
if ($mdFiles.Count -lt 12 -or $txtFiles.Count -lt 10) {
    L 'gem_package_incomplete=True'
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 5
}
L 'gem_package_complete=True'

try {
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
    New-Item -ItemType Directory -Force -Path $desktop | Out-Null
    $deskReadme = Join-Path $desktop 'love-letter-gem-README.md'
    $deskPrompt = Join-Path $desktop 'love-letter-gem-system-instructions.md'
    Copy-Item -LiteralPath (Join-Path $gemDir 'README-??????.md') -Destination $deskReadme -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path -LiteralPath $deskReadme)) { Copy-Item -LiteralPath ((Get-ChildItem -LiteralPath $gemDir -Filter 'README-*.md' | Select-Object -First 1).FullName) -Destination $deskReadme -Force }
    Copy-Item -LiteralPath ((Get-ChildItem -LiteralPath $gemDir -Filter 'Gem*.md' | Select-Object -First 1).FullName) -Destination $deskPrompt -Force
    L ('desktop_readme=' + (San $deskReadme) + ' exists=' + (Test-Path -LiteralPath $deskReadme))
    L ('desktop_prompt=' + (San $deskPrompt) + ' exists=' + (Test-Path -LiteralPath $deskPrompt))
} catch { L ('desktop_copy_error=' + (San $_.Exception.Message)) }
L ''

$rclone = Get-RcloneExe
if (-not $rclone) {
    L 'rclone_present=False'
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 2
}
L ('rclone_present=True path=' + $rclone)
$ver = Run-Capped 'rclone_version' {
    & $using:rclone version 2>&1 | Select-Object -First 2 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 60
foreach ($ln in (($ver.text -split "`r?`n") | Where-Object { $_.Trim() })) { L ('rclone_version| ' + (San $ln)) }

$about = Run-Capped 'about_probe' {
    & $using:rclone about $using:remoteWithColon --json 2>&1 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 90
$aboutOk = ($about.code -eq 0) -and ($about.text -match 'total')
L ('remote_about_ok=' + $aboutOk)
if (-not $aboutOk) {
    L 'remote_not_ready=True'
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 2
}

$dst = $remoteWithColon + $DriveDir
L ('push_start=True dst=' + $dst)
$copy = Run-Capped 'rclone_copy' {
    & $using:rclone copy $using:gemDir $using:dst --transfers 4 --checkers 8 2>&1 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 600
foreach ($ln in (($copy.text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 15)) { L ('copy| ' + (San $ln)) }
L ('copy_exit=' + $copy.code)
if ($copy.code -ne 0) {
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 3
}

$chk = Run-Capped 'rclone_check' {
    & $using:rclone check $using:gemDir $using:dst --one-way 2>&1 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 300
foreach ($ln in (($chk.text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 8)) { L ('check| ' + (San $ln)) }
L ('check_exit=' + $chk.code)

$lsf = Run-Capped 'rclone_lsf' {
    & $using:rclone lsf -R --files-only $using:dst 2>&1 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 180
$remoteFiles = @(($lsf.text -split "`r?`n") | Where-Object { $_.Trim() })
L ('gem_files_remote=' + $remoteFiles.Count)

$verifyOk = ($chk.code -eq 0 -and $remoteFiles.Count -ge 24)
L ('verify_ok=' + $verifyOk)
if (-not $verifyOk) {
    L 'LOVE_LETTER_GEM_PUSH_OK=False'
    W $report $lines
    exit 4
}

L ''
L ('drive_folder=' + $DriveDir)
L 'LOVE_LETTER_GEM_PUSH_OK=True'
W $report $lines
exit 0
