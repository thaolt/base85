#!/bin/sh

# Build script for static base85 binary
mkdir -p build

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    OUTPUT="build/base85.arm64"
else
    OUTPUT="build/base85.x86_64"
fi

gcc -static -o $OUTPUT main.c base85.c -Wall -Wextra -O2
strip $OUTPUT
echo "Static binary built and stripped successfully: $OUTPUT"
