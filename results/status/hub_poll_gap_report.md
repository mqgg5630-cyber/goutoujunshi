# 基座轮询诊断 · 2026-10-24 14:55 (UTC+08:00)

## 结论先说

**通道是通的，但这条分支上没有常驻轮询进程。** 14:36:52 那次成功是一次性扫描，不是持续 poll。所以“打通了”只证明了双向可达，不等于“会自动拉”。

## 证据（全部来自远端真实提交，可复核）

| 时间（UTC+8） | 事件 | 来源 |
| --- | --- | --- |
| 14:33:49 | 基座同步 `arena/01a101bf-goutoujunshi`，59 个文件 | 提交 `ff8060f`，作者 `git-sync-hub (LAPTOP-R77M5D6M)` |
| 14:33:59 | 基座同步 `arena/daf1bc30-goutoujunshi`，3 个文件 | 提交 `af1780e`，同作者 |
| 14:36:52 | 基座同步 `arena/e1541481-goutoujunshi`，4 个文件 | 提交 `8cc3b0d`，同作者 |
| 14:47:07 | 沙箱推送 `575ab6d`（4 文件） | 提交 `575ab6d`，作者 `Arena Agent` |
| 14:47–14:51 | 18 次 `git fetch`，每 15 秒一次，共约 4.5 分钟 | **远端无任何新提交** |
| 14:53:57 | 再次核对 `git ls-remote` | 分支仍停在 `575ab6d` |

三个分支的同步都集中在 14:33:49–14:36:52 这 3 分钟里，此后 20 多分钟全机零活动。这个形状像是**一次启动扫描后循环退出了**，而不是每个分支各有一个 2 分钟轮询的常驻进程。

## 为什么新分支默认没有 watcher

仓库里 `skills/git-sync` 的设计是**一个分支一个 watcher、一个分支一份配置**：

- `watch.ps1 -Register` 创建计划任务 `git-sync-watch-<repo>-<id>`，默认 `-Interval 2`（2 分钟一次）
- `sync.config.json` 里 `"branch"` 写死是哪一个分支，`code/local_check.ps1` 还会校验 config 的 branch 与 `HEAD` 一致
- `watch.ps1 -Focus` 会**暂停其它** `git-sync-watch-*` 任务，`-RestoreParked` 才恢复

也就是说：`arena/e1541481-goutoujunshi` 是 14:36 才出现的新分支，机器上大概率没有为它注册 watcher，那次同步更像是按需触发（回执里 `mode` 写的就是 `results-only-zero-window`，zero-window = 无窗口、一次性）。

历史记录里同样反复出现这种状态：`results/status/WATCHERS_RESTORED_R2.md` 记录过 5 个 watcher 中有 4 个处于 `Disabled`，需要手工恢复。

## 为什么我这边补不上

注册 watcher 需要在 `LAPTOP-R77M5D6M` 上执行一次计划任务注册（且 `-Headless` 还要管理员控制台）。沙箱只有 GitHub 这一个出口，无法远程在你的电脑上注册任务、也看不到 `%LOCALAPPDATA%\git-sync\` 的心跳文件。

## 关于桌面路径 `D:\桌面\测试成功.txt`

- 现有回执里出现过的落盘路径**只有** `E:\0github\results\goutoujunshi-<id>` 一种，从未出现过桌面路径。
- 仓库里 `download.ps1` 确实支持 `-Dest` 任意目录（robocopy），但那是本地脚本调用，不属于 results-only 静默模式。
- 所以：**目前不能**。要让文件落到 `D:\桌面\测试成功.txt`，基座侧需要增加一步“单文件覆盖到桌面”，否则只会在 `E:\0github\results\` 下出现。

## 已发出的请求（本次推送）

| 文件 | 作用 |
| --- | --- |
| `results/deliverable/测试成功.txt` | 待覆盖到桌面的正文，带本地/UTC 双时间戳 |
| `results/status/desktop_target.json` | 声明目标 `D:\桌面\测试成功.txt`、覆盖模式、备用路径、所需能力 |
| `results/status/hub_poll_gap_report.md` | 本文件，用于核对轮询缺口 |

## 一个时间戳异常，值得留意

- 我们分支的回执 `synced_at_utc = 06:36:52Z`，但对应提交 `a57162d` 是 **06:37:07Z 之后**才生成的 —— 回执时间**早于**被同步的提交本身。
- `daf1bc30` 分支的回执 `synced_at_utc = 06:33:58Z`，与其 payload 里自报的 `pushed_at_utc = 06:33:58Z` **完全一模一样**（秒级相同）。

两次都指向同一件事：基座回执的时间戳不是落盘当下读的本机时间（或本机时钟比沙箱慢 20–40 秒）。含义是：**回执里的时间不能当作“真的写盘了”的强证据**，只有路径与文件数能对上才算。
