#!/usr/bin/env bash
#
# crave/probe.sh - read-only environment probe for the Crave build image.
#
# Purpose: find out whether the currently available base project (LOS 23.2,
# Android 16) can host an Android 17 tree. Nothing is synced or compiled.
#
set -uo pipefail

sec() { printf '\n===== %s =====\n' "$*"; }

sec "system"
uname -a
cat /etc/os-release | head -5
nproc
free -g | head -2
df -h / | tail -2
echo "cwd=$(pwd)"

sec "toolchain"
for t in java javac python3 repo git git-lfs patchelf ccache ninja lz4 zstd rsync curl unzip; do
    p=$(command -v "$t" 2>/dev/null || true)
    printf '%-12s %s\n' "$t" "${p:-MISSING}"
done
echo
java -version 2>&1 | head -3
javac -version 2>&1 | head -2
python3 --version 2>&1
repo --version 2>&1 | head -2
git --version
git lfs version 2>&1 | head -1

sec "java target"
if command -v java >/dev/null 2>&1; then
    readlink -f "$(command -v java)"
fi

sec "android 17 prerequisites (informational)"
python3 - <<'PY'
import sys
print("python:", sys.version.split()[0])
try:
    import google.protobuf
    print("protobuf: present")
except Exception:
    print("protobuf: missing (may be vendored in tree)")
PY

sec "/opt/crave"
ls -la /opt/crave 2>/dev/null | head -30

sec "disk layout"
df -h /tmp /opt 2>/dev/null | head -6
mount | grep -E ' /(tmp|opt|crave)' | head -5

sec "env hints"
env | grep -i -E 'android|java|ccache|use_|out_dir' | sort | head -20

sec "done"
