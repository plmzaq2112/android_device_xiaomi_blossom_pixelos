#!/usr/bin/env bash
#
# 30-collect.sh - verify build artifacts and write reproducible metadata.
#
set -euo pipefail

TOP="${ANDROID_BUILD_TOP:-$(pwd)}"
cd "$TOP"

PRODUCT_OUT="${PRODUCT_OUT:-out/target/product/blossom}"
INFO="$PRODUCT_OUT/build-info.txt"

if [ ! -d "$PRODUCT_OUT" ]; then
    echo "FATAL: product out dir missing: $PRODUCT_OUT"
    exit 1
fi

ZIP=$(ls -1 "$PRODUCT_OUT"/PixelOS_blossom-*.zip 2>/dev/null | tail -n 1 || true)
if [ -z "$ZIP" ]; then
    echo "FATAL: no PixelOS_blossom-*.zip in $PRODUCT_OUT"
    exit 1
fi

echo "== 30-collect: artifacts =="
{
    echo "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "product_out=$PRODUCT_OUT"
    echo "rom_zip=$ZIP"
    echo "rom_zip_bytes=$(stat -c %s "$ZIP")"
    echo "rom_zip_sha256=$(sha256sum "$ZIP" | awk '{print $1}')"

    for img in boot.img dtbo.img recovery.img; do
        if [ -f "$PRODUCT_OUT/$img" ]; then
            echo "${img}_bytes=$(stat -c %s "$PRODUCT_OUT/$img")"
            echo "${img}_sha256=$(sha256sum "$PRODUCT_OUT/$img" | awk '{print $1}')"
        fi
    done

    # Upstream pins (guarded: repos may be missing in unusual trees)
    for d in device/xiaomi/blossom vendor/xiaomi/blossom \
             device/xiaomi/blossom-kernel hardware/mediatek \
             device/mediatek/sepolicy_vndr vendor/xiaomi/miuicamera; do
        if git -C "$d" rev-parse --short=12 HEAD >/dev/null 2>&1; then
            echo "commit:${d}=$(git -C "$d" rev-parse --short=12 HEAD)"
        fi
    done

    if [ -f device/xiaomi/blossom-kernel/kernel ]; then
        echo "kernel_sha256=$(sha256sum device/xiaomi/blossom-kernel/kernel | awk '{print $1}')"
    fi
} > "$INFO"

cat "$INFO"

echo
echo "== 30-collect: zip integrity =="
if command -v unzip >/dev/null 2>&1; then
    unzip -t "$ZIP" >/dev/null && echo "zip OK" || { echo "FATAL: zip corrupt"; exit 1; }
else
    echo "WARN: unzip not available, skipped zip test"
fi
