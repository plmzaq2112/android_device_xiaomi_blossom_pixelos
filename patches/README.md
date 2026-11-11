# patches/

本目录只存放**本工程新增**的补丁，用于修正 PixelOS 与 blossom 设备树之间的差异。

不在此目录的补丁：

- `device/xiaomi/blossom/patches/` 下的 22 个 crDroid 上游补丁，由上游
  `vendorsetup.sh` 在 envsetup 时用 `git am` 应用。上游脚本在失败时会
  `git am --skip` 静默跳过，因此 `scripts/00-preflight.sh` 会逐条打印
  `[ OK ]` / `[SKIP]`，把冲突留在日志里。

新增补丁的规则：

1. 先确认上游补丁没覆盖同一问题。
2. 一个补丁只做一件事，提交信息写明动机。
3. 加进 `patches/series`，格式：`<目标目录> <补丁相对路径>`。
4. 在 `docs/03-known-issues.md` 登记对应问题编号。
