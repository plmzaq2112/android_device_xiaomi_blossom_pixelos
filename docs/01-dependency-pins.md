# 依赖版本锁定

原则：**分支 + commit 双锁定**。分支名用于跟踪，commit 用于复现。

## 构建时实际参与编译的仓库

| 组件 | 仓库 | 分支 | 锁定 commit | 是否修改 |
|---|---|---|---|---|
| ROM | `PixelOS-AOSP/android_manifest` | `seventeen` | `29f6010bcd2bd4742502ea7ccee763c64f02a3c1` | 否 |
| 设备树 | `crdroidandroid/android_device_xiaomi_blossom` | `17.0` | `234c8c1c179af69b0e4259c353a08a7586b441dc` | 否 |
| Vendor | `crdroidandroid/proprietary_vendor_xiaomi_blossom` | `17.0` | `87d0882114fb2e880fb2299de15affe79e398236` | 否 |
| MTK HAL | `LineageOS/android_hardware_mediatek` | `lineage-24.0` | 随分支 | 否 |
| MTK sepolicy | `LineageOS/android_device_mediatek_sepolicy_vndr` | `lineage-24.0` | 随分支 | 否 |
| 相机 | `Jayedkhan800/vendor_xiaomi_miuicamera` | `main` | 随分支 | 否 |
| 产品覆盖 | `plmzaq2112/android_device_xiaomi_blossom_pixelos` | `main` | 本仓库 | 是（仅新增） |
| 预编译内核 | `plmzaq2112/android_device_xiaomi_blossom-kernel` | `pixelos-17` | 由内核构建产出 | 是（新增产物） |

## 内核

| 项 | 值 |
|---|---|
| 源码 | `plmzaq2112/dandelion-4.19-purity` |
| 分支 | `4.19.325-purity` |
| 锁定 commit | `155480951a28d98e82252753eb1e56997f5e7ae6` |
| defconfig | `arch/arm64/configs/blossom_purity_defconfig` |
| 编译 | clang 21 + LLD + `aarch64-linux-gnu-` |
| 产物 | `Image.gz`（gzip magic `1f 8b`） |

## 更新流程

1. 记录当前 `repo manifest -r` 输出（或逐个 `git -C <path> rev-parse HEAD`）。
2. 拉取上游新 commit 后，先在本地做只读 diff 审查。
3. 更新本文件与本仓库 README 中的 commit。
4. 提交、推送，然后在 Crave 上增量构建。
5. 构建失败时用旧 commit 复现，确认是上游回归而不是适配问题。

## 冻结策略

- 首次成功启动前，不更新设备树 / vendor / 内核的 commit。
- 阶段 6 排错期间同样冻结；每次只允许一个变量变化。
