# Arena handshake helper (git-sync-hub v4.0) — ASCII only on purpose, to avoid codepage issues.
# Idempotent. Prints a machine report to stdout so the hub can capture it.
$ErrorActionPreference = 'Continue'

$report = @()
$report += "=== ARENA HANDSHAKE REPORT ==="
$report += "time_utc     : " + (Get-Date).ToUniversalTime().ToString('o')
$report += "host         : $env:COMPUTERNAME"
$report += "user         : $env:USERNAME"
$report += "ps_version   : $($PSVersionTable.PSVersion)"
$report += "pwsh_exe     : " + (Get-Process -Id $PID).Path
$report += "cwd          : $(Get-Location)"
$report += "c_root       : $(Test-Path 'C:\')"
$report += "c_0github    : $(Test-Path 'C:\0github')"
$report += "d_desktop    : $(Test-Path 'D:\桌面')"
$report += "e_python     : $(Test-Path 'E:\spider\python.exe')"

try   { $report += "git_version  : " + ((git --version) -join ' ') } catch { $report += "git_version  : ERR $_" }
try   { $report += "git_toplevel : " + ((git rev-parse --show-toplevel) -join ' ') } catch { $report += "git_toplevel : ERR $_" }
try   { $report += "git_branch   : " + ((git rev-parse --abbrev-ref HEAD) -join ' ') } catch { $report += "git_branch   : ERR $_" }

try {
    $r = Get-ChildItem -Force 'D:\' -ErrorAction Stop | Select-Object -First 15 -ExpandProperty Name
    $report += "d_root_items : " + ($r -join ', ')
} catch { $report += "d_root_items : ERR $_" }

$report | ForEach-Object { Write-Output $_ }
