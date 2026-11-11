#!/usr/bin/env bash
#
# make-kernel-prebuilt.sh - build dandelion-4.19-purity and lay out the
# prebuilt kernel repository consumed by device/xiaomi/blossom/BoardConfig.mk.
#
# Usage:
#   make-kernel-prebuilt.sh <kernel-src> <out-dir> <stock-boot.img> <stock-dtbo.img>
#
# Requirements: clang 21, LLD, aarch64-linux-gnu binutils, python3.
# The kernel is built from the exact commit currently checked out in <kernel-src>.
# dtb.img / dtbo.img are taken from the device's stock images so that the DT
# blobs match the hardware (the upstream kernel project also keeps stock DT).
#
set -euo pipefail

KSRC="${1:?usage: make-kernel-prebuilt.sh <kernel-src> <out-dir> <stock-boot.img> <stock-dtbo.img>}"
OUT="${2:?}"
STOCK_BOOT="${3:?}"
STOCK_DTBO="${4:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"

[ -d "$KSRC" ] || { echo "FATAL: kernel source not found: $KSRC"; exit 1; }
[ -f "$STOCK_BOOT" ] || { echo "FATAL: stock boot image not found: $STOCK_BOOT"; exit 1; }
[ -f "$STOCK_DTBO" ] || { echo "FATAL: stock dtbo image not found: $STOCK_DTBO"; exit 1; }

mkdir -p "$OUT"

COMMIT="$(git -C "$KSRC" rev-parse HEAD)"
SHORT="$(git -C "$KSRC" rev-parse --short=12 HEAD)"
echo "== kernel commit: $COMMIT"

echo "== configure"
make -C "$KSRC" O="$KSRC/out-dandelion" ARCH=arm64 \
    CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
    LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
    STRIP=llvm-strip AR=llvm-ar blossom_purity_defconfig

echo "== build Image.gz"
make -C "$KSRC" O="$KSRC/out-dandelion" ARCH=arm64 \
    CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
    LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
    STRIP=llvm-strip AR=llvm-ar -j"$(nproc)" Image.gz

IMG="$KSRC/out-dandelion/arch/arm64/boot/Image.gz"
[ -s "$IMG" ] || { echo "FATAL: Image.gz not produced"; exit 1; }

echo "== collect artifacts"
cp "$IMG" "$OUT/kernel"
python3 "$HERE/extract-stock-dt.py" boot "$STOCK_BOOT" "$OUT/dtb.img"
python3 "$HERE/extract-stock-dt.py" dtbo "$STOCK_DTBO" "$OUT/dtbo.img"

cat > "$OUT/PROVENANCE.md" <<EOF
# Prebuilt kernel provenance

- Kernel source: plmzaq2112/dandelion-4.19-purity
- Branch: 4.19.325-purity
- Commit: $COMMIT
- Defconfig: blossom_purity_defconfig
- Built (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Toolchain: $(clang --version | head -1)

## Artifacts

| File | Bytes | SHA256 |
|---|---|---|
| kernel | $(stat -c %s "$OUT/kernel") | $(sha256sum "$OUT/kernel" | awk '{print $1}') |
| dtb.img | $(stat -c %s "$OUT/dtb.img") | $(sha256sum "$OUT/dtb.img" | awk '{print $1}') |
| dtbo.img | $(stat -c %s "$OUT/dtbo.img") | $(sha256sum "$OUT/dtbo.img" | awk '{print $1}') |

## DT blobs

\`dtb.img\` and \`dtbo.img\` are extracted from the device's stock images
($(basename "$STOCK_BOOT"), $(basename "$STOCK_DTBO")) so the device tree matches
the hardware. Only the kernel image is replaced; see
https://github.com/plmzaq2112/dandelion-4.19-purity for the source.
EOF

echo "== done: $OUT"
ls -l "$OUT"
cat "$OUT/PROVENANCE.md"
