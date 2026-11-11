#!/usr/bin/env bash
#
# crave/node.sh - executed on the Crave build node inside the workspace.
#
# Handles both cases:
#   * first run: no .repo yet -> repo init (PixelOS seventeen) + resync
#   * later runs: existing tree -> resync only (incremental)
#
# The workspace directory is the current directory when `crave run` is invoked.
#
set -euo pipefail

REPO_URL="https://github.com/plmzaq2112/android_device_xiaomi_blossom_pixelos.git"
REPO_DIR="/tmp/blossom-pixelos"
MANIFEST_URL="https://raw.githubusercontent.com/plmzaq2112/android_device_xiaomi_blossom_pixelos/main/local_manifests/pixelos-blossom.xml"
ROM_MANIFEST="https://github.com/PixelOS-AOSP/android_manifest.git"
ROM_BRANCH="${BLOSSOM_ROM_BRANCH:-seventeen}"

log() { printf '\n== %s ==\n' "$*"; }

log "fetch project config"
rm -rf "$REPO_DIR"
git clone --depth 1 "$REPO_URL" "$REPO_DIR"

# The workspace must be bound to a supported base project for Crave to resolve
# it (see docs/02-build-plan.md). Inside the job we switch the manifest to
# PixelOS 17, which is the documented "unsupported ROM" flow.
if [ ! -d .repo ]; then
    log "no manifest yet: repo init PixelOS ${ROM_BRANCH} (depth 1)"
    repo init -u "$ROM_MANIFEST" -b "$ROM_BRANCH" --git-lfs --depth 1
elif ! git -C .repo/manifests remote get-url origin 2>/dev/null | grep -q 'PixelOS-AOSP/android_manifest'; then
    log "workspace bound to another manifest: switching to PixelOS ${ROM_BRANCH}"
    repo init -u "$ROM_MANIFEST" -b "$ROM_BRANCH" --git-lfs --depth 1
fi

log "install local manifest"
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
cp "$REPO_DIR/local_manifests/pixelos-blossom.xml" .repo/local_manifests/

log "resync (platform script, keeps existing objects)"
/opt/crave/resync.sh

log "preflight"
bash "$REPO_DIR/scripts/00-preflight.sh"

log "curated patches"
bash "$REPO_DIR/scripts/10-apply-patches.sh"

log "build"
bash "$REPO_DIR/scripts/20-build.sh" "${BLOSSOM_RELEASE:-cp2a}" "${BLOSSOM_VARIANT:-userdebug}"

log "collect"
bash "$REPO_DIR/scripts/30-collect.sh"

log "diag"
bash "$REPO_DIR/scripts/90-diag.sh" || true
