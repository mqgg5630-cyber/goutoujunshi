# Arena handshake verify (git-sync-hub v4.0)
# NOTE: this file is saved as UTF-8 **with BOM** on purpose.
# PowerShell 5.1 decodes .ps1 as ANSI/GBK unless a BOM is present, which silently
# corrupts non-ASCII literals such as 'D:\桌面'. Keep the BOM.
$ErrorActionPreference = 'Continue'

$targets = @(
    'C:\0github\arena_hub_probe.txt',
    'D:\桌面\测试成功.txt',
    'D:\桌面\arena_hub_probe.txt'
)

$report = @()
$report += "=== ARENA HANDSHAKE VERIFY ==="
$report += "time_utc   : " + (Get-Date).ToUniversalTime().ToString('o')
$report += "host       : $env:COMPUTERNAME"
$report += "branch     : " + ((git rev-parse --abbrev-ref HEAD) -join ' ')

foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        $i = Get-Item -LiteralPath $t
        $len = (Get-Content -LiteralPath $t -Raw -Encoding UTF8).Length
        $report += ("PRESENT    : {0} | bytes={1} | chars={2} | mtime={3}" -f $t, $i.Length, $len, $i.LastWriteTime.ToString('s'))
    } else {
        $report += "MISSING    : $t"
    }
}

# Chinese-literal path resolution check (the thing the BOM fixes)
$report += "d_desktop  : " + (Test-Path -LiteralPath 'D:\桌面')
$report += "c_0github  : " + (Test-Path -LiteralPath 'C:\0github')
$report += "e_python   : " + (Test-Path -LiteralPath 'E:\spider\python.exe')

# Persist the report on the real machine (UTF-8, no BOM)
$out = 'C:\0github\arena_hub_report.txt'
try {
    ($report -join "`r`n") | Out-File -LiteralPath $out -Encoding UTF8
    $report += "WROTE      : $out"
} catch {
    $report += "WROTE_ERR  : $_"
}

$report | ForEach-Object { Write-Output $_ }
