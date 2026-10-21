#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tool_root=/workspace/tooling/luau
expected_commit=994b6416f1a2d16ac06c52b4e574bad5d8749053
mkdir -p /workspace/tooling
if [ ! -e "$tool_root" ]; then
    git clone --depth 1 --branch 0.699 https://github.com/luau-lang/luau.git "$tool_root"
fi
actual_commit=$(git -C "$tool_root" rev-parse HEAD)
if [ "$actual_commit" != "$expected_commit" ]; then
    echo "Existing Luau checkout differs from the pinned compiler. Preserve it and choose a separate tooling path." >&2
    exit 1
fi
make -C "$tool_root" config=release luau luau-compile -j2 > /tmp/thrift-luau-build.log 2>&1 || {
    tail -n 60 /tmp/thrift-luau-build.log >&2
    exit 1
}
cd "$repo_root"
LUAU="$tool_root/luau" LUAU_COMPILE="$tool_root/luau-compile" python3 tools/test.py
python3 tools/build.py
