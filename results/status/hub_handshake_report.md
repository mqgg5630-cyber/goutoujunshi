# Arena ⇄ LAPTOP-R77M5D6M 静默基座打通报告

**结论：通道已打通，可以正常投递真实任务。** 共 3 轮往返、30 个执行步骤、`exit_code` 全部为 0，落盘文件已用 SHA-256 逐字节校验。

- 仓库：`mqgg5630-cyber/goutoujunshi`
- 分支：`arena/d766ed90-goutoujunshi`
- 基座：`git-sync-hub v4.0`（`auto-poll-exec-and-sync-zero-window`，轮询 15s）
- 真机本地结果目录：`E:\0github\results\goutoujunshi-d766ed90-goutoujunshi`
- 回执：`results/status/hub_sync_receipt.json` ／ 日志：`results/status/hub_exec_output.txt`

## 1. 真机环境（实测）

| 项 | 值 |
| --- | --- |
| 主机名 | `LAPTOP-R77M5D6M` |
| 系统 | Windows 10（`10.0.26100`） |
| 账户 | `文少` |
| PowerShell | 5.1.26100.8875（`System32\WindowsPowerShell\v1.0\powershell.exe`） |
| Python | `E:\spider\python.exe` → 3.11.9 |
| Git | 2.54.0.windows.1 |
| 可用盘符 | `C:` `D:` `E:` |
| 关键路径 | `C:\0github` ✔ · `D:\桌面` ✔ · `E:\spider\python.exe` ✔ |

## 2. 落盘校验（第 3 轮实测）

| 目标文件 | 大小 | SHA-256 | 校验 |
| --- | --- | --- | --- |
| `C:\0github\arena_hub_probe.txt` | 113 B | `23383a4f…ddef6e` | 与仓库源内容逐字节一致 ✔ |
| `D:\桌面\测试成功.txt` | 106 B | `75e09b63…b10b7af` | 与仓库源内容逐字节一致 ✔（中文 72 字符 / 106 字节） |
| `D:\桌面\arena_hub_probe.txt` | 197 B | `b92d7b06…9224552` | 由 `results/status/hub_probe.txt` 拷贝，见下方第 5.3 条 ✔ |

另外脚本自身把一份报告写到了 `C:\0github\arena_hub_report.txt`（UTF-8，`REPORT_FILE=True`）。

## 3. 往返时延

| 轮次 | 内容 | 从 push 到回执可见 |
| --- | --- | --- |
| r1 | 初始握手（写盘 + PS + Python + 脚本） | ≈ 45 s |
| r2 | 落盘回读 + `.ps1` BOM 修复验证 | ≈ 45 s |
| r3 | SHA-256 逐字节校验 + UTF-8 输出探针 | ≈ 75 s |

轮询 15 s 一次，正常 1～3 个周期（15～45 s）内回推；等 60～90 s 足够，偶发可放宽到 2 min。

## 4. 已确认可用的任务字段

`results/status/hub_task.json` 中四个字段全部按文档生效：`write_files` / `copy_files` / `powershell[]` / `python[]`；`results/task/run.ps1` 也会被自动识别执行（无需在 JSON 里声明）。三者在同一轮里按「写文件 → 拷贝 → PowerShell → Python → 脚本」顺序执行。

## 5. 踩到的坑与正确姿势（下次直接用）

### 5.1 `.ps1` 必须存成 **UTF-8 with BOM**
第 1 轮 `run.ps1` 里 `Test-Path 'D:\桌面'` 返回 **False**（而 JSON 驱动的写盘同一路径却成功）。原因：PowerShell 5.1 对**无 BOM** 的 `.ps1` 按 ANSI/GBK 解码，脚本内的中文字面量被读坏。加 BOM 后同一行返回 **True**。
→ 结论：**脚本里要写中文路径，文件头必须有 `EF BB BF`**；或者干脆用 `$env:...`／ASCII 路径绕开。

### 5.2 回传 stdout 默认是 GBK，中文会变乱码且不可逆
第 1、2 轮里 `USER=文少`、`D:\桌面\测试成功.txt` 在日志中显示为 `????` / `锟斤拷`（双重编码，回不来）。
→ 修法（已验证）：脚本开头
```powershell
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$OutputEncoding            = New-Object System.Text.UTF8Encoding $false
```
```python
import sys; sys.stdout.reconfigure(encoding='utf-8')
```
第 3 轮加上后，日志里 `utf8_probe : 中文输出测试 OK`、`D:\桌面\测试成功.txt` 完全正常。
→ 注意：**这种编码设置是"每次进程调用"级别的**，JSON 里 `powershell[]` 的每一条是独立进程，需要各自设置。若不想管编码，就让脚本只打印 ASCII 标记 + 数字（长度/哈希/布尔），中文一律落在文件里。

### 5.3 `copy_files` 会把 LF 改写成 CRLF
仓库源 `results/status/hub_probe.txt` 是 193 B（LF），真机落地 197 B（CRLF），**恰好 +4 字节 = 4 行**；把本地内容 LF→CRLF 后 SHA-256 与真机完全一致（`b92d7b06…`）。
→ 结论：拷贝目标**不要**直接拿源文件的哈希做比对；要对齐哈希，先做行尾归一化，或改用 `write_files` 投递。

### 5.4 JSON 里的中文是安全的
`hub_task.json` 按 UTF-8 解析，中文路径 `D:\桌面\...` 与中文内容 `测试成功.txt` 写入均正确（`write_files` 目标哈希与本地源完全一致）。**首选 `write_files` 承载中文内容**，`copy_files` 用于搬运二进制/大文件更合适。

### 5.5 任务运行在**临时克隆**里，相对路径不持久
`git rev-parse --show-toplevel` 显示当前工作目录是
`C:\Users\文少\AppData\Local\Temp\git-sync-hub-ephemeral\<repo>-<branch>-<hash>`。
→ 结论：脚本里凡是要"留下东西"的写入，**必须用绝对盘符路径**（`C:\0github\...`、`D:\桌面\...`、`E:\...`）；仓库相对路径只在本次执行内有效。

### 5.6 每轮都会整体重放任务包
同一份 `hub_task.json` 在多轮里被反复执行（内容相同则幂等无害）。→ 真实任务请保证写盘/脚本**幂等**，或执行完把任务包改成 `"write_files": []` 之类的空壳避免重复副作用。

## 6. 下次投递真实任务的模板

```json
{
  "task_id": "有意义的名字-日期",
  "write_files": [
    { "path": "C:\\0github\\你的目录\\文件.txt", "content": "UTF-8 中文内容安全\n第二行" }
  ],
  "copy_files": [],
  "powershell": [
    "[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false; 'STEP=ps1 done'; Test-Path -LiteralPath 'D:\\桌面'"
  ],
  "python": [
    "import sys; sys.stdout.reconfigure(encoding='utf-8'); import hashlib; p=r'C:\\0github\\你的目录\\文件.txt'; print('SHA256=' + hashlib.sha256(open(p,'rb').read()).hexdigest())"
  ]
}
```

投递流程（已验证）：`git add -A results deliverable && git commit -m "hub-task: ..." && git push origin HEAD`，然后每 15 s `git fetch origin && git merge --ff-only origin/arena/d766ed90-goutoujunshi`，读 `results/status/hub_sync_receipt.json` 与 `hub_exec_output.txt` 即可。
