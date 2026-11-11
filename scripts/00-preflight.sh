#!/usr/bin/env bash
#
# 00-preflight.sh - read-only validation before a PixelOS blossom build.
#
# Run from the root of the PixelOS source tree (the directory that contains
# .repo/). Exits non-zero on any hard failure so that CI/Crave stops early.
#
set -uo pipefail

TOP="${ANDROID_BUILD_TOP:-$(pwd)}"
cd "$TOP" || { echo "FATAL: cannot cd to $TOP"; exit 1; }

fail=0
warn=0

ok()   { printf '  [ OK ] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=$((fail + 1)); }
note() { printf '  [WARN] %s\n' "$*"; warn=$((warn + 1)); }

echo "== 00-preflight: source tree =="
echo "TOP=$TOP"

# ---------------------------------------------------------------- tree layout
if [ -d .repo ]; then ok ".repo present"; else bad ".repo missing (not an Android tree)"; fi

check_file() { # path description
    if [ -s "$1" ]; then ok "$2 ($1)"; else bad "$2 missing ($1)"; fi
}
check_dir() {
    if [ -d "$1" ]; then ok "$2 ($1)"; else bad "$2 missing ($1)"; fi
}

echo
echo "== 00-preflight: required projects =="
check_file device/xiaomi/blossom/BoardConfig.mk            "upstream device tree BoardConfig"
check_file vendor/xiaomi/blossom/BoardConfigVendor.mk      "upstream vendor tree"
check_file device/mediatek/sepolicy_vndr/SEPolicy.mk       "MTK vendor sepolicy"
check_dir  hardware/mediatek                               "MTK hardware HAL"
check_file vendor/xiaomi/miuicamera/MiuiCamera.mk          "MiuiCamera (device.mk dependency)"
check_file device/xiaomi/blossom-pixelos/AndroidProducts.mk "PixelOS product overlay"

echo
echo "== 00-preflight: kernel artifacts =="
KDEV=device/xiaomi/blossom-kernel
if [ -s "$KDEV/kernel" ]; then
    magic=$(od -An -tx1 -N2 "$KDEV/kernel" | tr -d ' \n')
    case "$magic" in
        1f8b) ok "kernel is gzip (Image.gz)" ;;
        *)    note "kernel magic is $magic, expected 1f8b (gzip Image.gz)" ;;
    esac
else
    bad "missing $KDEV/kernel"
fi
check_file "$KDEV/dtb.img"  "prebuilt dtb.img"
check_file "$KDEV/dtbo.img" "prebuilt dtbo.img"

echo
echo "== 00-preflight: host tools =="
if command -v patchelf >/dev/null 2>&1; then
    ok "patchelf $(patchelf --version 2>/dev/null)"
else
    note "patchelf not found: device tree patch_camera.sh cannot inject libshim_utils.so"
fi

for t in git repo python3 unzip zip java; do
    if command -v "$t" >/dev/null 2>&1; then ok "$t"; else note "$t not found"; fi
done

# git am needs an identity, otherwise applyPatches.sh can spin forever in its
# "git am --skip" retry loop. Provide a node-local fallback when unset.
if [ -z "$(git config --global user.email || true)" ]; then
    git config --global user.email "crave@localhost" && note "set fallback git user.email"
fi
if [ -z "$(git config --global user.name || true)" ]; then
    git config --global user.name "Crave Builder" && note "set fallback git user.name"
fi

echo
echo "== 00-preflight: disk space =="
avail_kb=$(df -Pk "$TOP" | awk 'NR==2 {print $4}')
avail_gb=$((avail_kb / 1024 / 1024))
if [ "$avail_gb" -ge 60 ]; then ok "${avail_gb} GiB free"; else bad "only ${avail_gb} GiB free"; fi

echo
echo "== 00-preflight: upstream patch applicability (read-only) =="
# The crDroid device tree ships patches/<project>/*.patch and applies them via
# applyPatches.sh during envsetup. We only *report* applicability here; nothing
# is modified. Conflicts are expected to be triaged explicitly in phase 4.
if [ -d device/xiaomi/blossom/patches ]; then
    while IFS= read -r p; do
        rel=${p#device/xiaomi/blossom/patches/}
        proj=${rel%%/*}
        if [ -d "$proj" ] && git -C "$proj" apply --check "$TOP/$p" >/dev/null 2>&1; then
            printf '  [ OK ] %s\n' "$rel"
        else
            printf '  [SKIP] %s\n' "$rel"
        fi
    done < <(find device/xiaomi/blossom/patches -type f -name '*.patch' | sort)
else
    note "device/xiaomi/blossom/patches not found"
fi

echo
echo "== 00-preflight summary: ${fail} failure(s), ${warn} warning(s) =="
[ "$fail" -eq 0 ] || exit 1
exit 0
