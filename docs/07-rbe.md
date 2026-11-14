# RBE（远程构建执行）笔记

记录 2026-11-14 对社区 RBE 方案的核实结果。

## 社区说法

> `rbe_auto` → `source build/envsetup.sh` → `lunch <target>` → `m bacon`
> API Key 从 https://app.buildbuddy.io/ 获取，setup 时粘贴。
> 验证：`echo "USE_RBE=$USE_RBE jobs=$NINJA_REMOTE_NUM_JOBS"`

## 技术核实

| 项 | 结论 | 证据 |
|---|---|---|
| 原理 | AOSP 原生 RBE（reclient/reproxy）指向 BuildBuddy 的 REAPI 端点 | `USE_RBE`、`RBE_POOL` 存在于 `build/make/core/config.mk`（1307–1328 行） |
| 客户端 | PixelOS 17 manifest 已包含 reclient 预编译 | `default.xml` 第 947 行：`prebuilts/remoteexecution-client` |
| 免费额度 | BuildBuddy Personal（开源项目）免费：**最多 80 核远程构建**、100 GB 缓存传输 | https://www.buildbuddy.io/pricing/ |
| `rbe_auto` | Crave 镜像内的封装脚本，负责把 reclient 配到 BuildBuddy 并写入 Key | 仅在 Crave 节点上存在，本地无法查看 |

结论：**方案本身成立**，不是谣言。它能显著加速编译（RBE 承担 clang 等 action）。

## 但它解决不了当前阻塞

2026-11-14 复测：

- 全新工作区 + projectID 99（manifest 已正确绑定 `accupara/los23.2@lineage-23.2`）
- 提交 `echo` → **仍然 403 `User does not have permission`**

RBE 只是"让任务跑得更快"，前提是**能创建任务**。Crave 目前连任务都不让建，
所以 `rbe_auto` 无法使用。

## 安全规则（重要）

BuildBuddy API Key 等同于账号凭据：

1. **不要**贴到聊天、Issue、提交信息或仓库任何文件。
2. 本地存放建议：`~/.buildbuddy_key`，权限 `600`。
3. 自动传参时用环境变量或 stdin，**不要** `echo` 出来。
4. `rbe_auto` 是交互式粘贴；在 `crave run` 里需要确认它是否接受
   `BUILDBUDDY_API_KEY` 之类的环境变量，或用 `printf '%s\n' "$KEY" | rbe_auto`。
   这一点必须在真实节点上验证后才能写进脚本。
5. Key 泄露后立即在 BuildBuddy 控制台吊销并重建。

## 若 Crave 恢复写权限

```bash
rbe_auto                     # 粘贴 BuildBuddy API Key
source build/envsetup.sh
lunch custom_blossom-cp2a-userdebug
echo "USE_RBE=$USE_RBE jobs=$NINJA_REMOTE_NUM_JOBS"
m pixelos
```

注意：

- 首次构建建议先不开 RBE，确认常规编译能过；第二次再开 RBE 做加速对比。
- 记录 `USE_RBE` / `NINJA_REMOTE_NUM_JOBS` 的实际值到构建日志。
- 若远程执行失败，回退方式：unset `USE_RBE` 重新 `m`（增量，不需要 clean）。

## 若换到其他构建主机

RBE 的价值在于：**本地不需要 32 核**，只需要足够的磁盘与内存跑
Soong/ninja 调度与打包。

最低建议：

- 磁盘 ≥ 500 GB
- 内存 ≥ 16 GB（32 GB 更稳）
- Linux x86_64，JDK 满足 Android 17

在 Crave 之外使用 BuildBuddy RBE 需要自行配置 reclient（endpoint、平台属性、
API Key header）。本仓库暂未提供该配置，因为无法在真实节点上验证；
需要时再单独做一次最小验证。
