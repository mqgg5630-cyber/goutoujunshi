# t1_gdrive_push_gem_r1.ps1 - round 1.
# Push the distilled Gemini Gem knowledge library (deliverable\gem) to the
# user's Google Drive via rclone remote gdrive_jzthjyz (jzthjyz@gmail.com).
# If the remote is missing or its token is dead, run the cloud-interop setup
# script first (a browser OAuth page may open - the user approves it locally;
# never paste passwords/OAuth codes/2FA into chat). ASCII-only. No secrets
# printed. Exit codes: 0 ok, 2 remote not ready, 3 copy failed,
# 4 verify failed, 5 local gem package missing.

$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..\..')
$repo = (Get-Location).Path
$gemDir = Join-Path $repo 'deliverable\gem'
$cloudDir = Join-Path $repo 'results\cloud_interop'
New-Item -ItemType Directory -Force -Path $cloudDir | Out-Null
$report = Join-Path $cloudDir 'GEM_GDRIVE_PUSH_R1.md'
$lines = New-Object System.Collections.Generic.List[string]

$RemoteName = 'gdrive_jzthjyz'
$AccountEmail = 'jzthjyz@gmail.com'
$DriveDir = 'Arena/Gem/goutoujunshi'
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
# Run a block in a background job with a timeout. Native exit codes do not
# survive the job boundary, so every block appends '===EXITCODE:N' itself and
# Run-Capped parses it back out. Returns @{ ok; text; code; name }.
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

L '# Gemini Gem library -> Google Drive push r1'
L ('time=' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))
L ('host=' + $env:COMPUTERNAME)
L ('remote=' + $remoteWithColon)
L ('drive_dir=' + $DriveDir)
L ''

# 1. local package inventory
if (-not (Test-Path -LiteralPath $gemDir)) {
    L 'gem_dir_missing=True'
    L 'GDRIVE_GEM_PUSH_OK=False'
    W $report $lines
    exit 5
}
$mdFiles = @(Get-ChildItem -LiteralPath $gemDir -Filter '*.md' | Sort-Object Name)
$txtDir = Join-Path $gemDir 'txt'
$txtFiles = @()
if (Test-Path -LiteralPath $txtDir) { $txtFiles = @(Get-ChildItem -LiteralPath $txtDir -Filter '*.txt' | Sort-Object Name) }
$allLocal = @($mdFiles + $txtFiles)
L ('gem_md_files_local=' + $mdFiles.Count)
L ('gem_txt_files_local=' + $txtFiles.Count)
L 'gem_expected_md=12 gem_expected_txt=10'
if ($mdFiles.Count -lt 12 -or $txtFiles.Count -lt 10) {
    L 'gem_package_incomplete=True'
    L 'GDRIVE_GEM_PUSH_OK=False'
    W $report $lines
    exit 5
}
L 'gem_package_complete=True'
L ''

# 2. rclone present?
$rclone = Get-RcloneExe
if (-not $rclone) {
    L 'rclone_present=False - the setup script below will install it'
} else {
    L ('rclone_present=True path=' + $rclone)
    $ver = Run-Capped 'rclone_version' {
        & $using:rclone version 2>&1 | Select-Object -First 2 | Out-String
        Write-Output ('===EXITCODE:' + $LASTEXITCODE)
    } 60
    foreach ($ln in (($ver.text -split "`r?`n") | Where-Object { $_.Trim() })) { L ('rclone_version| ' + (San $ln)) }
}

# 3. remote ready? (probe by about - do NOT trust listremotes alone)
function Test-RemoteReady {
    if (-not $script:rclone) { return $false }
    # make the script-scope values LOCAL so $using: inside the job block
    # (which captures the calling scope) can see them
    $rclone = $script:rclone
    $remoteWithColon = $script:remoteWithColon
    $r = Run-Capped 'about_probe' {
        & $using:rclone about $using:remoteWithColon --json 2>&1 | Out-String
        Write-Output ('===EXITCODE:' + $LASTEXITCODE)
    } 90
    $ready = ($r.code -eq 0) -and ($r.text -match 'total')
    return $ready
}
$aboutOk = Test-RemoteReady
L ('remote_about_ok=' + $aboutOk)

# 4. if not ready, run the cloud-interop setup script (installs rclone if
#    needed, creates/repairs the remote; browser OAuth may open)
if (-not $aboutOk) {
    L 'setup_needed=True'
    try {
        $note = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Arena_Gem_GDrive_OAuth_Note.txt'
        Set-Content -LiteralPath $note -Encoding UTF8 -Value @(
            'Arena is pushing the Goutoujunshi Gem library to Google Drive.',
            ('Use account: ' + $AccountEmail),
            'If a browser authorization page opens, approve it locally.',
            'Do not paste passwords, OAuth tokens, or 2FA codes into chat.'
        )
        Start-Process -FilePath 'notepad.exe' -ArgumentList $note -ErrorAction SilentlyContinue | Out-Null
        L ('oauth_note_on_desktop=' + (San $note))
    } catch { L ('oauth_note_WARN=' + (San $_.Exception.Message)) }

    $setupScript = Join-Path $repo 'skills\cloud-interop\scripts\setup-gdrive-rclone.ps1'
    if (-not (Test-Path -LiteralPath $setupScript)) {
        L 'setup_script_missing=True'
        L 'GDRIVE_GEM_PUSH_OK=False'
        W $report $lines
        exit 2
    }
    $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $setup = Run-Capped 'gdrive_setup' {
        & $using:psExe -NoProfile -ExecutionPolicy Bypass -File $using:setupScript `
            -RemoteName $using:RemoteName -AccountEmail $using:AccountEmail -Scope drive 2>&1 | Out-String
        Write-Output ('===EXITCODE:' + $LASTEXITCODE)
    } 1500
    foreach ($ln in (($setup.text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 40)) { L ('setup| ' + (San $ln)) }
    if ($setup.text -match 'GDRIVE_RCLONE_READY=True') { $aboutOk = $true }
    if (-not $aboutOk) {
        $rclone = Get-RcloneExe
        $aboutOk = Test-RemoteReady
    }
    L ('remote_about_ok_after_setup=' + $aboutOk)
    if (-not $aboutOk) {
        L 'remote_not_ready=True (OAuth not completed yet - approve the browser page and the next round will pass)'
        L 'GDRIVE_GEM_PUSH_OK=False'
        W $report $lines
        exit 2
    }
}

# 5. push the library
$dst = $remoteWithColon + $DriveDir
L ('push_start=True dst=' + $dst)
$copy = Run-Capped 'rclone_copy' {
    & $using:rclone copy $using:gemDir $using:dst --transfers 4 --checkers 8 2>&1 | Out-String
    Write-Output ('===EXITCODE:' + $LASTEXITCODE)
} 600
foreach ($ln in (($copy.text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -Last 15)) { L ('copy| ' + (San $ln)) }
L ('copy_exit=' + $copy.code)
if ($copy.code -ne 0) {
    L 'GDRIVE_GEM_PUSH_OK=False'
    W $report $lines
    exit 3
}

# 6. verify: one-way hash check + remote file count
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

$verifyOk = ($chk.code -eq 0 -and $remoteFiles.Count -ge ($allLocal.Count))
L ('verify_ok=' + $verifyOk)

if (-not $verifyOk) {
    L 'GDRIVE_GEM_PUSH_OK=False'
    W $report $lines
    exit 4
}

L ''
L ('drive_folder=' + $DriveDir)
L 'GDRIVE_GEM_PUSH_OK=True'
W $report $lines
exit 0
