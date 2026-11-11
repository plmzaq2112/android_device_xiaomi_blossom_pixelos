# 阶段 1 审查报告（存档）

> 采集时间：2026-11-11。所有检查均为只读；未修改任何上游仓库。
> 端侧历史状态见独立审计：Phh GSI Android 11 + ArrowOS 11 vendor（permissive SELinux、2021 安全补丁）。

## 1. 本地环境

| 项目 | 实际状态 |
|---|---|
| WSL2 发行版 | Ubuntu 26.04.1 LTS（非 Kali） |
| 内核 / CPU / 内存 | 6.6.114.1-microsoft-standard-WSL2 / 16 线程 / 7.6 GiB |
| 磁盘 | 1007 G，可用 939 G |
| Git / Repo | 2.53.0 / launcher 2.54 |
| git-lfs | 已补装 3.8.1（`~/.local/bin`） |
| patchelf | 已补装 0.19.3（`~/.local/bin`） |
| Crave CLI | 已补装 0.2-7183（`~/.local/bin`），凭据未配置 |
| 构建工具链 | clang 21.1.8 / lld 21.1.8 / aarch64-linux-gnu-gcc 已存在 |
| GitHub CLI | Windows 侧已登录 `plmzaq2112`（repo/workflow/gist/read:org） |
| WSL 出网 | 需代理：`http://172.29.192.1:10808`（Windows 10808，允许局域网） |

## 2. 上游源码

| 组件 | 仓库 | 分支 | Commit | 结论 |
|---|---|---|---|---|
| PixelOS | `PixelOS-AOSP/android_manifest` | `seventeen` | `29f6010bcd2bd4742502ea7ccee763c64f02a3c1` | AOSP `android-17.0.0_r1`，含 `vendor/lineage`(PixelOS fork) / `vendor/custom` / `device/lineage/sepolicy` |
| 设备树 | `crdroidandroid/android_device_xiaomi_blossom` | `17.0` | `234c8c1c179af69b0e4259c353a08a7586b441dc` | 488 文件，2026-10-29 仍在维护，Android 17 指纹 |
| Vendor | `crdroidandroid/proprietary_vendor_xiaomi_blossom` | `17.0` | `87d0882114fb2e880fb2299de15affe79e398236` | 908 文件，17.0 完整 |
| 内核 | `plmzaq2112/dandelion-4.19-purity` | `4.19.325-purity` | `155480951a28d98e82252753eb1e56997f5e7ae6` | 4.19.325，`blossom_purity_defconfig`，已在 Android 16 验证 |

PixelOS manifest 缺失（必须由 local manifest 补齐）：
`hardware/mediatek`、`device/mediatek/sepolicy_vndr`、`vendor/xiaomi/miuicamera`、
`device/xiaomi/blossom*`。

## 3. 设备树关键事实

- 产品：`lineage_blossom.mk`，lunch `lineage_blossom-userdebug`；
  PixelOS 使用 `custom_<codename>`，因此需要薄覆盖产品（本仓库）。
- 平台：`mt6765`，A-only，非 A/B，动态分区，AVB 开启。
- 内核：`TARGET_FORCE_PREBUILT_KERNEL := true`，
  `TARGET_PREBUILT_KERNEL := device/xiaomi/blossom-kernel/kernel`，
  另有 `dtb.img` 与 `dtbo.img`。**不需要内核源码进 ROM 树**。
- 硬依赖 include：
  - `vendor/xiaomi/miuicamera/SEPolicy.mk`（BoardConfig）
  - `vendor/xiaomi/miuicamera/MiuiCamera.mk`（device.mk）
  - `device/lineage/sepolicy/libion/sepolicy.mk`
  - `device/mediatek/sepolicy_vndr/SEPolicy.mk`
- `vendorsetup.sh` 每次 envsetup：
  1. `patch_camera.sh`：用 patchelf 给 `camerahalserver` 注入 `libshim_utils.so`；
  2. `applyPatches.sh`：`git am` 22 个上游补丁，失败时 `--skip` 静默跳过；
  3. `SKIP_ABI_CHECKS=true`、`TARGET_BOARD_PLATFORM=mt6765`。
- 分区：super 6.5 GiB，system 1.09 GiB，product 1.48 GiB，boot/recovery 64 MiB，dtbo 8 MiB。

## 4. 风险清单

| 编号 | 风险 | 处置 |
|---|---|---|
| R1 | PixelOS 产品前缀 `custom_` ≠ 上游 `lineage_` | 薄覆盖产品目录，不改上游 |
| R2 | 缺 `vendor/xiaomi/miuicamera` | local manifest 补齐（解析期硬依赖） |
| R3 | 缺 MTK HAL / sepolicy | local manifest 补齐 |
| R4 | 22 个 crDroid 补丁在 PixelOS 上可能冲突，上游会静默跳过 | preflight 逐条报告；必要时用 `patches/series` 显式接管 |
| R5 | 构建节点可能无 patchelf | preflight 检查；缺失则相机 shim 不会注入，需备选方案 |
| R6 | 分区容量 vs PixelOS GMS 体积 | 首轮观察，超限再申请调整（属分区相关改动，需审批） |
| R7 | 内核仅验证 Android 16 | 原样接入，Android 17 实测 |
| R8 | 上游关闭 VINTF 强制（`PRODUCT_ENFORCE_VINTF_MANIFEST := false` 等） | 首轮保留并登记，后续收紧 |
| R9 | fingerprint 覆盖与 PixelOS 完整性属性可能冲突 | 沿用上游指纹，阶段 4 对齐 PixelOS 策略 |
| R10 | SELinux 必须 Enforcing | 产物测试项，禁止以 permissive 换编译通过 |
| R11 | Crave FOSS 项目列表未知 | 用户提供 crave.conf 后 `crave clone list` 确认 |
