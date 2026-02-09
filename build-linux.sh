#!/bin/sh

# Build script for static Linux base85 binary
mkdir -p build

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    OUTPUT="build/base85.linux.arm64"
else
    OUTPUT="build/base85.linux.x86_64"
fi

gcc -static -o $OUTPUT main.c base85.c -Wall -Wextra -O2
strip $OUTPUT
echo "Static Linux binary built and stripped successfully: $OUTPUT"
