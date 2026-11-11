# 已知问题

编号与 `docs/00-audit.md` 的风险清单一致。状态：`open` / `mitigated` / `closed`。

## R1 PixelOS 产品前缀差异 — mitigated

上游设备树只声明 `lineage_blossom`，PixelOS 使用 `custom_blossom`。
本仓库用 `device/xiaomi/blossom-pixelos/` 薄覆盖解决，未修改上游。

验证点：`lunch` 列表中出现 `custom_blossom-*`，且 `printconfig` 中
`TARGET_DEVICE=blossom`、`TARGET_PRODUCT=custom_blossom`。

## R2 缺少 MiuiCamera 仓库 — mitigated

`BoardConfig.mk` include 了 `vendor/xiaomi/miuicamera/SEPolicy.mk`，
`device.mk` inherit 了 `MiuiCamera.mk`，缺仓库会在解析期 fatal。
local manifest 已加入 `Jayedkhan800/vendor_xiaomi_miuicamera`（支持 dandelion）。

待验证：MiuiCamera APK 在 Android 17 上是否可运行；若不可用，评估是否
仅保留 SEPolicy 而移除 APK（需用户决定，属于功能取舍）。

## R3 缺少 MTK HAL / sepolicy — mitigated

local manifest 已加入 `hardware/mediatek` 与 `device/mediatek/sepolicy_vndr`
（均为 `lineage-24.0`）。版本差异导致的编译错误在阶段 6 处理。

## R4 上游补丁在 PixelOS 上冲突 — open

`applyPatches.sh` 会 `git am --skip` 静默跳过失败补丁。影响：

- 可能缺失 media/Bluetooth/framework 修复；
- 构建仍显示成功，问题在运行期才暴露。

措施：`scripts/00-preflight.sh` 逐条输出 `[ OK ]` / `[SKIP]`。
阶段 4 根据清单决定：接受、改用本仓库补丁、或明确放弃并记录原因。

## R5 构建节点缺少 patchelf — open

`patch_camera.sh` 依赖 patchelf，给 `camerahalserver` 注入 `libshim_utils.so`。
若节点无 patchelf，cameraserver 可能无法加载 shim。

措施：preflight 报告。备选方案（需审批）：
1. 在自建 vendor 覆盖层提供已注入 shim 的二进制；
2. 在 `crave run` 内使用平台允许的方式获取 patchelf（不得擅自 apt 安装）。

## R6 分区容量不足 — open

PixelOS 带 GMS 与 Pixel 应用，可能超出 system 1.09 GiB / product 1.48 GiB。

措施：首轮构建观察 `*.img` 大小与实际 super 使用量。
若超限，最小幅度调整 BoardConfig 尺寸（涉及分区，需用户批准）。

## R7 内核仅验证 Android 16 — open

`4.19.325-purity` 在 crDroid 16 上验证通过；Android 17 未验证。

措施：先原样接入。若出现 binder/BPF/新 syscall 缺失，再评估最小 backport；
不做与启动无关的性能改动。

## R8 上游关闭 VINTF 强制 — open

`PRODUCT_ENFORCE_VINTF_MANIFEST := false`、
`PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false`、
`ro.kernel.version=4.19.191` 覆盖。

措施：首轮保留（否则大概率无法通过 VINTF 检查），在构建记录中登记；
待系统稳定后再评估逐项收紧。

## R9 指纹与完整性 — open

设备树用 Pixel 17 指纹覆盖 `BuildFingerprint`，PixelOS 自身也管理
fingerprint/PIF 相关属性，可能互相覆盖。

措施：阶段 4 对照 PixelOS 官方设备树的做法统一，避免重复覆盖。

## R10 SELinux 必须 Enforcing — open

历史系统（Phh GSI）运行在全局 permissive。新 ROM 必须验证：

```
adb shell getenforce   # 期望 Enforcing
```

禁止以 permissive 或删除策略换取编译/启动成功。

## R11 Crave 项目未知 — open

尚未确认 FOSS 账号可用的项目列表。若无 PixelOS 17 项目，按平台"非官方 ROM"
规则选最接近的基底项目，在 `crave run` 内重新 `repo init`（不得 `rm -rf *`）。

## 其他待办

- 预编译内核的 dtb.img / dtbo.img 来源与校验和需写入
  `android_device_xiaomi_blossom-kernel/PROVENANCE.md`。
- `crave.yaml` 顶层 key 必须是项目实名，首次创建时确认。
