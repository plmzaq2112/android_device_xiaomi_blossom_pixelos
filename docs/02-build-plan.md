# 首次构建计划

状态：**未提交**。需完成第 0 节全部前置条件并获得用户批准。

## 0. 前置条件

| 编号 | 条件 | 状态 |
|---|---|---|
| P1 | Crave 账号 + `crave.conf` | 完成（`~/crave.conf`） |
| P2 | 确认可用项目 | 完成：**无 Android 17 项目**，最高 LOS 23.2（Android 16） |
| P3 | 选择基底项目并创建工作区 | **待用户决策** |
| P4 | 两个 GitHub 仓库公开可克隆 | 完成 |
| P5 | 预编译内核产物 | 完成（kernel 9,359,188 B / dtb 127,044 B / dtbo 144,732 B） |
| P6 | 上游 22 个补丁适用性清单 | 首次 preflight 产出 |
| P7 | 用户批准首次全量构建 | 待批准 |

### P2 实测结果（crave 0.2-7183，2026-11-11）

```
Id  Name            Source Url
81  LOS 16          https://github.com/accupara/los16.git
93  LOS 22.1        https://github.com/accupara/los22.git
99  LOS 23.2        https://github.com/accupara/los23.2.git
80  LOS CM 12.1     https://github.com/accupara/los-cm12.1.git
77  ROM Dumper      https://github.com/DumprX/DumprX
78  TWRP            minimal-manifest-twrp/platform_manifest_twrp_aosp
59  crave-devspaces
```

CLI 事实（已用 `--help` 核实）：

- **没有 `crave clone` 子命令**（fosson.top 文档已过时）。
- 工作区就是调用 `crave run` 时所在的目录；项目与平台按次指定。
- 首次运行需要在 `crave run` 内执行 `repo init` + `/opt/crave/resync.sh`
  （平台文档"非官方 ROM"流程允许此做法，禁止在 devspace 内同步）。

### 基底选择（待决策）

| 方案 | 说明 | 风险 |
|---|---|---|
| A. 用 LOS 23.2（A16）作"最接近基底" | 平台文档允许选最接近的兄弟项目；首次 run 内重新 `repo init` PixelOS 17 | 项目镜像可能缺 Android 17 工具链（JDK/Python），属环境错误；需实测 |
| B. 申请 Android 17 基底 | 通过 Discord/Telegram 向 Crave 申请新增项目 | 等待时间不可控，但最合规 |
| C. 改做 PixelOS 16 | 与基底版本完全一致 | 偏离 Android 17 目标 |

决策：**不申请新项目，直接采用 A**，先做只读探测。

### 工作区绑定（实测要点）

本地机器没有 `/crave-devspaces`（那是 devspace 内部路径）。实测结论：

1. 工作区必须先用**受支持项目**的 manifest 做一次 `repo init`（只 init，
   不同步），否则 `crave run` 报
   `Could not get project information for <path>`。
2. `--platform` 必须是该项目允许的平台，否则报
   `Invalid platform for project`；省略则用项目默认平台。
3. 首次任务内再把 manifest 切到 PixelOS 17，然后 `/opt/crave/resync.sh`。
   这正是平台文档的"非官方 ROM"流程。

本轮使用的本地工作区：`/home/a12bbb/crave-workspaces/PixelOS17`，
绑定 `accupara/los23.2@lineage-23.2`。

### 探测任务

```bash
crave run --projectID 99 --no-patch --no-artifacts --detached --json -- \
  "curl -fsSL <probe.sh> -o /tmp/probe.sh && bash /tmp/probe.sh"
```

探测脚本：`crave/probe.sh`（只打印系统/工具链信息，不同步、不编译）。

## 1. 拟用命令

```bash
# 一次性：创建工作区目录（之后 crave run 在其内部执行）
mkdir -p /crave-devspaces/PixelOS17

# 每次构建（首次会自动 repo init + resync）
cd /crave-devspaces/PixelOS17
./crave/run.sh <projectID> /crave-devspaces/PixelOS17 [platform]
```

`crave/run.sh` 在节点上执行 `crave/node.sh`，顺序为：

1. `git clone --depth 1` 本仓库到 `/tmp/blossom-pixelos`
2. 若 `.repo` 不存在：`repo init -u PixelOS-AOSP/android_manifest -b seventeen --git-lfs --depth 1`
3. 安装 local manifest 到 `.repo/local_manifests/`
4. `/opt/crave/resync.sh`
5. `scripts/00-preflight.sh`（缺依赖立即失败）
6. `scripts/10-apply-patches.sh`（当前 series 为空）
7. `scripts/20-build.sh cp2a userdebug`
8. `scripts/30-collect.sh`
9. `scripts/90-diag.sh`

## 2. 目标配置

| 项 | 值 |
|---|---|
| Product | `custom_blossom` |
| Lunch | `custom_blossom-cp2a-userdebug`（release 名以 `lunch --help` 为准） |
| Build target | `m pixelos` |
| 内核 | 预编译 `device/xiaomi/blossom-kernel/{kernel,dtb.img,dtbo.img}` |
| 分区 | 上游 BoardConfig（super 6.5 GiB / system 1.09 GiB / product 1.48 GiB） |

## 3. 资源预估

- 首次 `resync`：Android 17 全树，节点磁盘与时间由平台决定，通常 20–60 分钟。
- 编译：32 核节点约 60–120 分钟；首次无缓存更久。
- 产物：ROM zip（约 1.5–2.5 GiB）+ boot.img + dtbo.img + build-info.txt。

## 4. 产物与拉取

```
out/target/product/blossom/PixelOS_blossom-*.zip
out/target/product/blossom/boot.img
out/target/product/blossom/dtbo.img
out/target/product/blossom/build-info.txt
out/verbose.log.gz
```

只拉取以上文件；不拉整棵 `out/`。

## 5. 失败处理约定

1. 保存 `out/error.log` + `out/verbose.log.gz` 尾部 + `scripts/90-diag.sh` 输出。
2. 定位**首个**有效错误（不是连锁错误）。
3. 分类：源码错误 / 环境错误 / 平台错误。
4. 最小修改，重新 preflight，再由用户批准下一次构建。
5. 禁止 `make clean`、`rm -rf out`、`--clean`；优先增量。

## 6. 回滚

- 工作区保留：不删除 `/crave-devspaces/PixelOS17`。
- 仓库回滚：`git revert` 适配提交（不 force push）。
- 内核回滚：预编译仓库切回上一个 tag/commit 并重新构建。
- 设备回滚：沿用既有 boot.img 备份（用户执行刷写）。
