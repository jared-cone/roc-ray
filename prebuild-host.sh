#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

if [ -z "${ZIG:-}" ]; then
  echo "INFO: The ZIG environment variable was not set."
  export ZIG=$(which zig)
fi

# Build with zig
# --release=fast gives best runtime performance
# --release=safe gives better debugging for the host
$ZIG build --release=fast

# Re-package platform archives into prebuilt-platfrom
if [[ "$(uname)" == "Darwin" ]]; then
    rm -f platform/macos-arm64.a
    libtool -static -o platform/macos-arm64.a zig-out/lib/*
elif [[ "$(uname)" == "Linux" ]]; then
    rm -f platform/linux-x64.a

    # bust open each of the archives and repackage into new archive
    cd zig-out/lib/
    ar x libraylib.a
    ar x librocray.a
    cd ../../
    ar rcs platform/linux-x64.a zig-out/lib/*.o
else
    echo "Unsupported operating system"
fi