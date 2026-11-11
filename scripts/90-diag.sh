#!/usr/bin/env bash
#
# 90-diag.sh - dump diagnostics that are useful when a build fails.
# Output goes to stdout so Crave keeps it in the job log.
#
set -uo pipefail
TOP="${ANDROID_BUILD_TOP:-$(pwd)}"
cd "$TOP" 2>/dev/null || exit 1

echo "== system =="
uname -a
nproc
free -h || true
df -h "$TOP" | tail -2

echo
echo "== tools =="
git --version
command -v patchelf >/dev/null && patchelf --version
command -v clang >/dev/null && clang --version | head -2
python3 --version 2>/dev/null

echo
echo "== git identity =="
git config --global user.name || true
git config --global user.email || true

echo
echo "== manifest =="
if [ -f .repo/manifest.xml ]; then
    ls -l .repo/manifest.xml
    grep -o 'name="[^"]*"' .repo/manifest.xml | head -40
fi
ls .repo/local_manifests 2>/dev/null || echo "no local_manifests"

echo
echo "== project revisions =="
for d in device/xiaomi/blossom vendor/xiaomi/blossom \
         device/xiaomi/blossom-kernel hardware/mediatek \
         device/mediatek/sepolicy_vndr vendor/xiaomi/miuicamera \
         device/xiaomi/blossom-pixelos; do
    if git -C "$d" rev-parse --short=12 HEAD >/dev/null 2>&1; then
        printf '%-40s %s\n' "$d" "$(git -C "$d" rev-parse --short=12 HEAD)"
    else
        printf '%-40s %s\n' "$d" "MISSING"
    fi
done

echo
echo "== kernel artifact =="
ls -l device/xiaomi/blossom-kernel 2>/dev/null || echo "kernel dir missing"

echo
echo "== upstream patch status =="
if [ -d device/xiaomi/blossom/patches ]; then
    find device/xiaomi/blossom/patches -name '*.patch' | wc -l
    find device/xiaomi/blossom/patches -name '*.patch' | sort
fi

echo
echo "== last build errors (if any) =="
if [ -f out/error.log ]; then
    tail -n 80 out/error.log
else
    echo "no out/error.log"
fi
