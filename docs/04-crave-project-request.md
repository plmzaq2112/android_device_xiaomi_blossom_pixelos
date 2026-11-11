# Crave 基底项目申请

## 结论（2026-11-11 实测）

- Crave CLI `0.2-7183` 只暴露 `crave admin project {reinit,status}`，
  **没有创建项目的命令**；项目（镜像 + 源码快照 + 平台配置）由 Crave 管理员维护。
- 账号可见项目最高为 `LOS 23.2`（Android 16），没有 Android 17 基底。
- 但平台文档允许"非官方 ROM"流程：选最接近的基底，在 `crave run` 内重新
  `repo init` 目标 ROM。因此**不强制**需要新项目。

## 两条路径

| 路径 | 做法 | 优点 | 风险 |
|---|---|---|---|
| 使用 LOS 23.2 基底 | `crave run --projectID 99` 内 `repo init` PixelOS 17 | 立即可用，不需要等待 | 项目镜像可能缺 Android 17 工具链（JDK/Python/soong 依赖），属环境错误 |
| 申请 Android 17 项目 | 向 Crave 管理员提交申请 | 镜像与项目缓存专为 A17 准备，最稳 | 等待时间不可控 |

## 申请文案（可直接发到 Discord / Telegram）

> 频道：`#requests`（Discord）或官方 Telegram 公告群对应请求入口。
> 发送前请确认平台当前公告，避免维护窗口期。

```
Hi Crave team,

Could you please add an Android 17 build project for FOSS users?

Suggested name : PixelOS 17
Source manifest: https://github.com/PixelOS-AOSP/android_manifest.git
Branch         : seventeen
Android base   : 17 / CP2A (AOSP tag android-17.0.0_r1)
Build target   : m pixelos
Reference      : LOS 23.2 project (id 99) as the closest existing base

I'm building an unofficial PixelOS 17 port for Xiaomi Redmi 9A (blossom,
MT6765). All sources are public:
  https://github.com/plmzaq2112/android_device_xiaomi_blossom_pixelos
  https://github.com/plmzaq2112/android_device_xiaomi_blossom-kernel

If a dedicated project is not possible right now, I'll use LOS 23.2 as the
base project and re-init the PixelOS 17 manifest inside `crave run`, as
described in the FOSS "unsupported ROM" guide. Please let me know if that is
acceptable.

Thanks!
```

## 发送后

1. 等待管理员回复，不要在维护/升级公告期间提交任务。
2. 拿到项目 ID 后，更新：
   - `docs/02-build-plan.md` 的 P2/P3
   - `crave/run.sh` 的示例 projectID
   - `crave/crave.yaml` 的顶层 key（必须是项目实名）
3. 再走"首次构建"审批。
