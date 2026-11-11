# android_device_xiaomi_blossom_pixelos

PixelOS 17（Android 17 / CP2A）非官方适配工程，目标设备为小米 Redmi 9A 家族
（统一设备树 `blossom`：dandelion / angelica / angelican / cattail / angelicain）。

本仓库**不存放** PixelOS 源码，也不 fork / 修改 crDroid 官方仓库。
它只提供：local manifest、产品薄覆盖、补丁清单、构建脚本、Crave 配置与文档。

## 当前状态

| 阶段 | 状态 |
|---|---|
| 阶段 1 环境与源码审查 | 完成，见 `docs/00-audit.md` |
| 阶段 2 深度源码审查 | 进行中 |
| 阶段 3 仓库建立 | 完成（本仓库） |
| 阶段 4 设备适配 | 未开始 |
| 阶段 5 首次构建 | 未开始（等待 Crave 项目确认） |
| 阶段 6 错误迭代 | 未开始 |
| 阶段 7 产物与设备测试 | 未开始 |

## 上游版本锁定

详见 `docs/01-dependency-pins.md`。摘要：

| 组件 | 仓库 | 分支 | Commit |
|---|---|---|---|
| PixelOS manifest | `PixelOS-AOSP/android_manifest` | `seventeen` | `29f6010` |
| 设备树 | `crdroidandroid/android_device_xiaomi_blossom` | `17.0` | `234c8c1` |
| Vendor | `crdroidandroid/proprietary_vendor_xiaomi_blossom` | `17.0` | `87d0882` |
| 内核源码 | `plmzaq2112/dandelion-4.19-purity` | `4.19.325-purity` | `1554809` |
| MTK HAL | `LineageOS/android_hardware_mediatek` | `lineage-24.0` | 随分支 |
| MTK sepolicy | `LineageOS/android_device_mediatek_sepolicy_vndr` | `lineage-24.0` | 随分支 |
| 相机 | `Jayedkhan800/vendor_xiaomi_miuicamera` | `main` | 随分支 |

## 设计要点

1. **不改上游设备树**。PixelOS 使用 `custom_<codename>` 产品命名，
   因此在 `device/xiaomi/blossom-pixelos/` 增加薄覆盖产品，继承
   `device/xiaomi/blossom/device.mk`，BoardConfig 仍由上游设备树提供
   （`PRODUCT_DEVICE := blossom`）。
2. **内核走预编译**。上游 `BoardConfig.mk` 已设定
   `TARGET_FORCE_PREBUILT_KERNEL := true`，内核镜像来自
   `device/xiaomi/blossom-kernel/{kernel,dtb.img,dtbo.img}`。
   内核由 `dandelion-4.19-purity` 单独构建并发布到独立仓库，
   避免 ROM 构建受内核工具链影响。
3. **补丁显式化**。不依赖上游 `applyPatches.sh` 的 `git am --skip`
   （它会静默丢弃冲突补丁）。本仓库用 `patches/series` 显式声明，
   `scripts/10-apply-patches.sh` 逐条 `git apply --check`，失败即停。

## 目录结构

```
.
├── docs/                          # 审查、依赖锁定、构建计划、已知问题
├── local_manifests/
│   └── pixelos-blossom.xml        # 同步时放入 .repo/local_manifests/
├── device/xiaomi/blossom-pixelos/
│   ├── AndroidProducts.mk
│   └── custom_blossom.mk
├── patches/
│   ├── series                     # 补丁顺序（相对路径）
│   └── README.md
├── scripts/
│   ├── 00-preflight.sh            # 只读环境/依赖校验
│   ├── 10-apply-patches.sh        # 显式补丁应用
│   ├── 20-build.sh                # envsetup + lunch + m pixelos
│   ├── 30-collect.sh              # 产物校验与校验和
│   └── 90-diag.sh                 # 诊断信息汇总（日志用）
├── crave/
│   ├── crave.yaml                 # 产物清单与主机名忽略
│   └── run.sh                     # crave run 内执行的命令序列
└── tools/
    ├── make-kernel-prebuilt.sh    # 内核 → 预编译仓库
    └── kernel-prebuilt-README.md
```

## 构建入口（Crave FOSS）

```bash
crave clone list                       # 确认项目 ID
crave clone create --projectID <id> /crave-devspaces/PixelOS17
cd /crave-devspaces/PixelOS17
crave run --no-patch -- "$(cat /path/to/crave/run.sh)"
```

实际命令见 `crave/run.sh` 与 `docs/02-build-plan.md`。

## 审批与安全边界

- 不修改 PixelOS / crDroid / LineageOS 上游仓库。
- 不关闭 SELinux、不通过删除模块或屏蔽错误换取编译成功。
- 不执行 `make clean`、`rm -rf out`、`crave run --clean`（除经批准）。
- 刷机操作一律由用户执行，本仓库不包含自动刷写脚本。
