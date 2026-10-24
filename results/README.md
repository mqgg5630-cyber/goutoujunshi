# results/ · 结果同步目录

本目录是沙箱与本地静默基座之间**唯一的结果通道**：只走 Git（提交 + 推送 + 回执），不安装、不运行任何本地弹窗脚本，不需要在本地终端执行命令。

## 目录约定

| 路径 | 用途 | 写入方 |
| --- | --- | --- |
| `results/reports/` | 可交付的报告、校验输出、分析结果 | 沙箱（提交推送） |
| `results/status/hub_sync_request.json` | 本次同步请求的机器可读清单（分支、文件清单、回执路径） | 沙箱（提交推送） |
| `results/status/session_report.md` | 本次同步的人类可读说明 | 沙箱（提交推送） |
| `results/status/hub_sync_receipt.json` | 基座落盘回执（含 `E:\0github\results\...` 本地路径与同步文件数） | 本地基座（自动回推） |

## 同步协议（仅结果模式）

1. 沙箱把结果文件写入 `results/`，执行 `git add results && git commit -m "sync: push results to local hub" && git push origin HEAD`。
2. 本地基座从 GitHub 拉取当前 `arena/*` 分支，把 `results/` 增量落盘到 `E:\0github\results\`。
3. 落盘完成后，基座把回执写到 `results/status/hub_sync_receipt.json` 并 `git push` 回**同一分支**（只允许快进推送，不改写历史）。
4. 沙箱在推送后按 15 秒间隔、最长 90 秒轮询 `git fetch`，读取该回执并汇报本地落盘路径与同步文件数。

## 回执字段（基座侧必须遵守）

```json
{
  "schema": "goutoujunshi.hub-sync-receipt/v1",
  "host": "LAPTOP-R77M5D6M",
  "branch": "arena/e1541481-goutoujunshi",
  "commit": "<基座实际落盘的提交 SHA>",
  "local_root": "E:\\0github\\results",
  "files": ["...相对路径..."],
  "file_count": 4,
  "synced_at": "<ISO-8601 UTC>"
}
```

## 边界

- 沙箱**不会**也无法直接访问 `LAPTOP-R77M5D6M`：GitHub 仓库是唯一可信通道，回执必须由基座真实回推，沙箱不代写、不模拟回执。
- 本轮只打通静默基座这一条通道；`main` 及除当前 `arena/*` 之外的分支暂停打通，沙箱不向其它分支推送。
