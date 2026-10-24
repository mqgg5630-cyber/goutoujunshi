# results/ — Arena ⇄ 本地静默基座（git-sync-hub v4.0）通道

本目录用于和 LAPTOP-R77M5D6M 上的永久静默基座通信。

## 目录约定

| 路径 | 方向 | 用途 |
| --- | --- | --- |
| `results/status/hub_task.json` | Arena → 真机 | 任务包（write_files / copy_files / powershell / python） |
| `results/task/run.ps1` | Arena → 真机 | 可选 PowerShell 脚本任务（本次为诊断上报） |
| `results/status/hub_sync_receipt.json` | 真机 → Arena | 回执（tasks_executed / copied_targets / local_results_dir） |
| `results/status/hub_exec_output.txt` | 真机 → Arena | 真机执行完整 stdout / stderr |

## 本次任务：握手自检（arena-handshake-2026-10-24）

写入 / 拷贝目标：

- `C:\0github\arena_hub_probe.txt`（中文 + ASCII 混合内容）
- `D:\桌面\测试成功.txt`
- `D:\桌面\arena_hub_probe.txt`（由 `results/status/hub_probe.txt` 拷贝）

同时通过 PowerShell 与 Python 回报主机名、解释器路径、盘符可用性与 git 状态。

回执返回后，Arena 侧会把结论写入 `results/status/hub_handshake_report.md`。
