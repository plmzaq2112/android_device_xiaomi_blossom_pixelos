#!/usr/bin/env bash
#
# crave/probe-rbe.sh - read-only probe for RBE support in the build image.
#
set -uo pipefail
sec() { printf '\n===== %s =====\n' "$*"; }

sec "system"
date -u
uname -a
nproc
free -g | head -2
df -h / | tail -2

sec "rbe binaries"
for t in rbe_auto reproxy bootstrap reclient ninja clang python3 java repo git-lfs patchelf; do
    p=$(command -v "$t" 2>/dev/null || true)
    printf '%-12s %s\n' "$t" "${p:-MISSING}"
done

sec "rbe_auto (if present)"
if command -v rbe_auto >/dev/null 2>&1; then
    file "$(command -v rbe_auto)" 2>/dev/null || true
    head -40 "$(command -v rbe_auto)" 2>/dev/null || true
else
    echo "rbe_auto not found in PATH"
fi

sec "/opt/crave"
ls -la /opt/crave 2>/dev/null | head -30

sec "rbe/reclient hints in environment"
env | grep -i -E 'rbe|reclient|reproxy|ninja_remote|buildbuddy' || echo "none"

sec "build/make RBE support (requires synced tree)"
if [ -f build/make/core/config.mk ]; then
    grep -n -E 'USE_RBE|RBE_POOL|NINJA_REMOTE' build/make/core/config.mk | head -20 || true
    grep -rn -E 'NINJA_REMOTE_NUM_JOBS' build/make/core/*.mk 2>/dev/null | head -10 || true
else
    echo "no build/make in this workspace (not synced)"
fi

sec "java/python"
java -version 2>&1 | head -3
python3 --version 2>&1

sec "done"
