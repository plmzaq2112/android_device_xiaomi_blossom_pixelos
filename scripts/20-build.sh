#!/usr/bin/env bash
#
# 20-build.sh - lunch the PixelOS blossom product and build.
#
# Usage: 20-build.sh [release] [variant]
#   release defaults to $BLOSSOM_RELEASE or "cp2a"
#   variant defaults to $BLOSSOM_VARIANT or "userdebug"
#
set -euo pipefail

TOP="${ANDROID_BUILD_TOP:-$(pwd)}"
cd "$TOP"

RELEASE="${1:-${BLOSSOM_RELEASE:-cp2a}}"
VARIANT="${2:-${BLOSSOM_VARIANT:-userdebug}}"

echo "== 20-build: envsetup =="
# shellcheck disable=SC1091
source build/envsetup.sh

echo "== 20-build: lunch custom_blossom-${RELEASE}-${VARIANT} =="
if ! lunch "custom_blossom-${RELEASE}-${VARIANT}"; then
    echo "lunch failed; available releases for this product:"
    lunch --help 2>&1 | sed -n '1,60p' || true
    exit 1
fi

echo "== 20-build: target config =="
printconfig 2>/dev/null | egrep '^(TARGET_PRODUCT|TARGET_RELEASE|TARGET_BUILD_VARIANT|TARGET_DEVICE|OUT_DIR)=' || true

echo "== 20-build: m pixelos =="
m pixelos
