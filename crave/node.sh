#!/usr/bin/env bash
#
# crave/node.sh - executed on the Crave build node inside the source tree.
#
# This file is fetched by crave/run.sh and is intentionally self-contained:
# it fetches the rest of this repository, installs the local manifest,
# resyncs, runs preflight, applies curated patches, builds and collects.
#
set -euo pipefail

REPO_URL="https://github.com/plmzaq2112/android_device_xiaomi_blossom_pixelos.git"
REPO_DIR="/tmp/blossom-pixelos"
PROXY="${BLOSSOM_PROXY:-}"

log() { printf '\n== %s ==\n' "$*"; }

if [ -n "$PROXY" ]; then
    export http_proxy="$PROXY" https_proxy="$PROXY"
fi

log "fetch project config"
rm -rf "$REPO_DIR"
git clone --depth 1 "$REPO_URL" "$REPO_DIR"

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
