#!/usr/bin/env bash
#
# crave/run.sh - submit a build from the local machine (WSL).
#
# CLI note (verified against crave 0.2-7183, 2026-11-11):
#   * there is NO `crave clone` subcommand anymore
#   * the workspace is simply the current directory when `crave run` is called
#   * project + platform are selected per invocation
#
# Usage:
#   ./crave/run.sh <projectID> <workspace-dir> [platform]
#
# Example:
#   ./crave/run.sh 99 /crave-devspaces/PixelOS17 linux32
#
# Requires: crave CLI + valid ${HOME}/crave.conf (API key).
# Keep the workspace directory name stable: it is part of the cache key.
#
set -euo pipefail

PROJECT_ID="${1:?usage: run.sh <projectID> <workspace-dir> [platform]}"
WORKSPACE="${2:?usage: run.sh <projectID> <workspace-dir> [platform]}"
PLATFORM="${3:-${BLOSSOM_PLATFORM:-}}"
NODE_SH_URL="https://raw.githubusercontent.com/plmzaq2112/android_device_xiaomi_blossom_pixelos/main/crave/node.sh"

if [ ! -f "$HOME/crave.conf" ] && [ ! -f ./crave.conf ]; then
    echo "FATAL: crave.conf not found (expected \$HOME/crave.conf)"
    echo "       Download it from foss.crave.io -> Downloads."
    exit 1
fi

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo "Submitting build:"
echo "  projectID : $PROJECT_ID"
echo "  workspace : $WORKSPACE"
echo "  platform  : ${PLATFORM:-<project default>}"
echo "  node.sh   : $NODE_SH_URL"

ARGS=(run --projectID "$PROJECT_ID" --no-patch)
[ -n "$PLATFORM" ] && ARGS+=(--platform "$PLATFORM")

crave "${ARGS[@]}" -- \
    "curl -fsSL '$NODE_SH_URL' -o /tmp/blossom-node.sh && bash /tmp/blossom-node.sh"
