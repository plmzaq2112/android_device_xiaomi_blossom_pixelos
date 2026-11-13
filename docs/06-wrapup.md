# 项目收尾（2026-11-13）

## 收尾原因

Crave FOSS 免费构建通道已不可用，且从证据看不是短暂的排队问题：

| 时间（UTC） | 证据 |
|---|---|
| 11-11 11:34 | 我们提交只读探测任务 309487，进入队列 |
| 11-11 16:06 | 任务被平台 SIGINT 终止（exit 130，无任何日志） |
| 11-11 ~ 11-13 | `foss.crave.io` 前端 JS 持续 **503**（Docker Flow Proxy: No server available） |
| 11-12 02:04 | 创建任务开始返回 **403 `User does not have permission`** |
| 11-12 15:17 | 仅 CI 账号（`runnervm7aw5e`）有任务完成 |
| 11-13 14:18 | 换项目（LOS 22.1）测试仍 403 → 账号级限制 |
| 11-13 之后 | 不再有普通账号可创建任务的迹象 |

结论：控制面只读可用，但**普通 FOSS 账号的构建写入口已关闭**。
继续重试没有意义，且有触发平台风控的风险，因此收尾。

## 已交付内容

### 1. 设备适配仓库
`https://github.com/plmzaq2112/android_device_xiaomi_blossom_pixelos`
分支 `main` @ `112c660`

```
README.md                     项目说明与上游版本锁定
docs/00-audit.md              阶段 1 环境与源码审查
docs/01-dependency-pins.md    依赖 commit 锁定 + DT blob 校验和
docs/02-build-plan.md         构建计划、Crave 工作区约束
docs/03-known-issues.md       R1–R11 风险与处置
docs/04-crave-project-request.md  （未使用）A17 项目申请文案
docs/05-build-log.md          构建/故障记录
docs/06-wrapup.md             本文件
local_manifests/pixelos-blossom.xml   7 个仓库的 local manifest
device/xiaomi/blossom-pixelos/        PixelOS 产品薄覆盖（custom_blossom）
scripts/00-preflight.sh       只读环境/依赖校验
scripts/10-apply-patches.sh   显式补丁应用（失败即停）
scripts/20-build.sh           envsetup + lunch + m pixelos
scripts/30-collect.sh         产物校验与 SHA256
scripts/90-diag.sh            诊断信息
crave/node.sh                 节点执行序列（含首次 repo init）
crave/run.sh                  本地提交入口
crave/probe.sh                只读环境探测
crave/crave.yaml              产物清单
tools/extract-stock-dt.py     从原厂镜像提取 dtb/dtbo
tools/make-kernel-prebuilt.sh 内核构建 + 预编译仓库打包
```

### 2. 预编译内核仓库
`https://github.com/plmzaq2112/android_device_xiaomi_blossom-kernel`
分支 `main` / `pixelos-17` @ `69f1cbc`

| 文件 | 大小 | SHA256 |
|---|---|---|
| `kernel` | 9,359,188 | `2d39e1dccd054f00bdb69a4d27cad3f57e3acb12b39d30b6bf72e139d7002448` |
| `dtb.img` | 127,044 | `82bb85356992b8007bf90df26902bbdb93ad4f4a9670e2ac341d5d38a509320e` |
| `dtbo.img` | 144,732 | `4e02a5c2b9b4791c5e4c35cd40df2d5c787cbbe29bb08c2eeae8e9f9dca135e9` |

- 内核源码：`plmzaq2112/dandelion-4.19-purity` @ `1554809`，`blossom_purity_defconfig`，clang 21。
- `dtb.img` 与上游预编译仓库 SHA256 完全一致；`dtbo.img` 有效载荷逐字节一致。
- 完整构建与来源记录在仓库 `PROVENANCE.md`。

## 阶段完成度

| 阶段 | 状态 |
|---|---|
| 1 环境检查与源码审查 | ✅ 完成 |
| 2 深度源码审查 | 🟡 部分（补丁清单与依赖已梳理，未做逐条冲突验证） |
| 3 项目仓库 | ✅ 完成 |
| 4 设备适配 | 🟡 骨架完成（产品覆盖、manifest），未在真实源码树上验证 |
| 5 构建准备 | ✅ 脚本与计划完成，**未执行首次构建** |
| 6 错误迭代 | ⛔ 被平台阻断 |
| 7 产物与设备测试 | ⛔ 未开始 |

## 未验证项（恢复构建后必须检查）

1. 22 个 crDroid 上游补丁在 PixelOS 17 上的实际适用性（`00-preflight.sh` 会逐条打印）。
2. 构建节点是否有 `patchelf`（`patch_camera.sh` 依赖）。
3. 分区容量是否足够（system 1.09 GiB / product 1.48 GiB）。
4. 内核 4.19.325 在 Android 17 上的兼容性（仅验证过 Android 16）。
5. SELinux 是否 Enforcing。
6. `custom_blossom` 产品与 PixelOS common 的配置冲突（指纹、GMS）。

## 迁移到其他构建环境

本仓库的脚本除 `crave/node.sh` 外都与平台无关，可在任意 Linux x86_64 环境使用。

最低要求：

- 64 位 Linux，≥ 32 GB RAM（推荐 64 GB）
- ≥ 500 GB 可用磁盘
- JDK 版本满足 Android 17（以 `build/make` 的检查为准）
- `repo`、`git-lfs`、`python3`、`unzip`、`ccache`（可选）

流程：

```bash
mkdir pixelos17 && cd pixelos17
repo init -u https://github.com/PixelOS-AOSP/android_manifest.git -b seventeen --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/repo/local_manifests/pixelos-blossom.xml .repo/local_manifests/
repo sync -c -j8

export ANDROID_BUILD_TOP=$PWD
bash /path/to/repo/scripts/00-preflight.sh
bash /path/to/repo/scripts/10-apply-patches.sh

source build/envsetup.sh
lunch custom_blossom-cp2a-userdebug
m pixelos

bash /path/to/repo/scripts/30-collect.sh
```

## 若 Crave FOSS 恢复

1. 打开控制台，**重新生成 API Key**，覆盖 `~/crave.conf`。
2. 用 `crave run --projectID 99 --no-patch --no-artifacts -- echo ok` 验证写权限。
3. 权限恢复后，按 `docs/02-build-plan.md` 提交探测与首次构建。
4. 不要把 Token 写入本仓库或聊天记录。

## 备注

- 本地 WSL 工作区保留：`~/crave-workspaces/PixelOS17`（仅 22 MB manifest）。
- 诊断用 `~/crave-workspaces/Diag93` 可随时删除。
- 内核源码与构建输出保留在 `~/pixelos-build/`（未提交到 Git）。
