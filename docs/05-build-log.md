# 构建记录

按时间倒序。每条记录：时间（UTC / CST）、Job、命令、结果、判断。

## 2026-11-11 · Job 309487 · 只读探测（被平台终止）

| 项 | 值 |
|---|---|
| 提交时间 | 2026-11-11 11:34 UTC（19:34 CST） |
| 项目 | LOS 23.2（projectID 99） |
| 工作区 | `/home/a12bbb/crave-workspaces/PixelOS17` |
| 命令 | `curl probe.sh && bash probe.sh`（只打印环境信息） |
| 结束时间 | 2026-11-11 16:06 UTC（2026-11-12 00:06 CST） |
| 结果 | `FAILED`，exit code 130（SIGINT） |
| 日志 | 无（`getlog` 报 `Could not get project root/url`；`fetchdiagnostics` 报不可用） |

### 同期观察

- `foss.crave.io/bundle.*.js` 返回 **503**：
  `Docker Flow Proxy: No server is available to handle this request`。
- 全平台历史任务最后一次完成时间：2026-11-11 01:29 UTC；
  之后到本次记录为止没有任何任务完成。
- 控制面（认证 / 项目列表 / 任务提交 / 历史查询）正常。

### 判断

任务在排队约 4.5 小时后被平台侧终止，且未产生任何执行日志，
时间点与 Web 前端 503、全平台无任务完成重合。
**结论：平台维护/故障期间清理排队任务，不是命令或仓库的问题。**

### 处置

- 不立即重新提交，避免在维护窗口继续占用队列。
- 恢复判据（同时满足）：
  1. `https://foss.crave.io/bundle.17b6e26f340054b9e91e.js` 返回 200；
  2. 新提交的探测任务在合理时间内离开 `queued`；
  3. 历史记录里出现新的完成任务。
- 恢复后先重跑本探测，再谈首次全量构建。

## 模板

```
## YYYY-MM-DD · Job <id> · <用途>

- 提交 / 结束（UTC）：
- 项目 / 平台：
- 命令：
- 结果 / exit code：
- 首个有效错误：
- 分类：源码 / 环境 / 平台
- 处置与下一步：
```
