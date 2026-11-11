#!/usr/bin/env bash
#
# 10-apply-patches.sh - apply extra patches listed in patches/series.
#
# Unlike the upstream applyPatches.sh, this script never skips a failed patch:
# every patch is checked with "git apply --check" first and the build stops on
# the first failure so the error is visible in the Crave log.
#
# series format (two columns, '#' comments allowed):
#   <target directory in source tree>   <patch path relative to repo root>
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERIES="$REPO_ROOT/patches/series"
TOP="${ANDROID_BUILD_TOP:-$(pwd)}"

if [ ! -f "$SERIES" ]; then
    echo "10-apply-patches: no series file, nothing to do"
    exit 0
fi

count=0
while IFS= read -r line; do
    line="${line%%#*}"
    # trim leading/trailing whitespace
    line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$line" ] || continue

    target="$(printf '%s' "$line" | awk '{print $1}')"
    patch_rel="$(printf '%s' "$line" | awk '{print $2}')"
    patch="$REPO_ROOT/$patch_rel"

    if [ ! -f "$patch" ]; then
        echo "FATAL: series references missing patch: $patch_rel"
        exit 1
    fi
    if [ ! -d "$TOP/$target" ]; then
        echo "FATAL: target directory missing: $target"
        exit 1
    fi

    echo "== applying $patch_rel -> $target"
    if ! git -C "$TOP/$target" apply --check "$patch"; then
        echo "FATAL: patch does not apply cleanly: $patch_rel"
        echo "       Resolve the conflict or update patches/series before rebuilding."
        exit 1
    fi
    git -C "$TOP/$target" am --keep-cr "$patch"
    count=$((count + 1))
done < "$SERIES"

echo "10-apply-patches: applied $count patch(es)"
