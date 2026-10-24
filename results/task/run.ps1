# Arena handshake verify (git-sync-hub v4.0)
# UTF-8 with BOM on purpose: PowerShell 5.1 decodes .ps1 as ANSI/GBK without a BOM,
# which corrupts non-ASCII literals such as 'D:\桌面'.
$ErrorActionPreference = 'Continue'
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    $OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch { }

$targets = @('C:\0github\arena_hub_probe.txt', 'D:\桌面\测试成功.txt', 'D:\桌面\arena_hub_probe.txt')
$report = @()
$report += "=== ARENA HANDSHAKE VERIFY (r3) ==="
$report += "time_utc   : " + (Get-Date).ToUniversalTime().ToString('o')
$report += "host       : $env:COMPUTERNAME"
$report += "cp_out     : " + [Console]::OutputEncoding.WebName
$report += "utf8_probe : 中文输出测试 OK"
$report += "d_desktop  : " + (Test-Path -LiteralPath 'D:\桌面')
$report += "c_0github  : " + (Test-Path -LiteralPath 'C:\0github')
$report += "e_python   : " + (Test-Path -LiteralPath 'E:\spider\python.exe')

foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        $i = Get-Item -LiteralPath $t
        $h = (Get-FileHash -LiteralPath $t -Algorithm SHA256).Hash.ToLower()
        $report += ("PRESENT    : {0} | bytes={1} | sha256={2}" -f $t, $i.Length, $h)
    } else {
        $report += "MISSING    : $t"
    }
}

try {
    ($report -join "`r`n") | Out-File -LiteralPath 'C:\0github\arena_hub_report.txt' -Encoding UTF8
    $report += "WROTE      : C:\0github\arena_hub_report.txt"
} catch { $report += "WROTE_ERR  : $_" }

$report | ForEach-Object { Write-Output $_ }
