# 首次构建计划

状态：**未提交**。需完成第 0 节全部前置条件并获得用户批准。

## 0. 前置条件

| 编号 | 条件 | 状态 |
|---|---|---|
| P1 | Crave 账号 + `~/crave.conf`（API Key） | 待用户提供 |
| P2 | `crave clone list` 确认可用项目（PixelOS 17 或最接近的基底） | 待确认 |
| P3 | 创建 Crave 工作区并固定目录名 `/crave-devspaces/PixelOS17` | 待执行 |
| P4 | 两个 GitHub 仓库公开可克隆 | 本仓库已推送后确认 |
| P5 | 预编译内核产物（kernel/dtb.img/dtbo.img）就绪 | 待内核构建 |
| P6 | 上游 22 个补丁的适用性清单已生成 | preflight 首次运行产出 |
| P7 | 用户批准首次全量构建 | 待批准 |

## 1. 拟用命令

```bash
# 一次性：创建工作区（需 P1/P2）
crave clone create --projectID <id> /crave-devspaces/PixelOS17
cp crave/crave.yaml /crave-devspaces/PixelOS17/crave.yaml   # 顶层 key 改成项目实名

# 每次构建
cd /crave-devspaces/PixelOS17
./crave/run.sh <id> /crave-devspaces/PixelOS17
```

`crave/run.sh` 在节点上执行 `crave/node.sh`，顺序为：

1. `git clone --depth 1` 本仓库到 `/tmp/blossom-pixelos`
2. 安装 local manifest 到 `.repo/local_manifests/`
3. `/opt/crave/resync.sh`
4. `scripts/00-preflight.sh`（缺依赖立即失败）
5. `scripts/10-apply-patches.sh`（当前 series 为空）
6. `scripts/20-build.sh cp2a userdebug`
7. `scripts/30-collect.sh`

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
