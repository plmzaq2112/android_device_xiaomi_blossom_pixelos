#!/usr/bin/env bash
#
# crave/run.sh - submit a build from the local machine (WSL).
#
# Usage:
#   ./crave/run.sh <projectID> [workspace-dir]
#
# Example:
#   ./crave/run.sh 42 /crave-devspaces/PixelOS17
#
# Requires: crave CLI + valid ${HOME}/crave.conf (API key).
# The workspace directory name matters for cache persistence: keep it stable.
#
set -euo pipefail

PROJECT_ID="${1:?usage: run.sh <projectID> [workspace-dir]}"
WORKSPACE="${2:-/crave-devspaces/PixelOS17}"
NODE_SH_URL="https://raw.githubusercontent.com/plmzaq2112/android_device_xiaomi_blossom_pixelos/main/crave/node.sh"

if [ ! -f "$HOME/crave.conf" ] && [ ! -f ./crave.conf ]; then
    echo "FATAL: crave.conf not found (expected \$HOME/crave.conf)"
    echo "       Download it from foss.crave.io -> Downloads."
    exit 1
fi

if [ ! -d "$WORKSPACE" ]; then
    echo "FATAL: workspace not found: $WORKSPACE"
    echo "       Create it once with:"
    echo "         crave clone list"
    echo "         crave clone create --projectID $PROJECT_ID $WORKSPACE"
    exit 1
fi

cd "$WORKSPACE"

echo "Submitting build:"
echo "  projectID : $PROJECT_ID"
echo "  workspace : $WORKSPACE"
echo "  node.sh   : $NODE_SH_URL"

crave run --projectID "$PROJECT_ID" --no-patch -- \
    "curl -fsSL '$NODE_SH_URL' -o /tmp/blossom-node.sh && bash /tmp/blossom-node.sh"
