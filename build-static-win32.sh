#!/bin/sh

# Build script for static Windows base85 binary
mkdir -p build

# Use MinGW-w64 32-bit compiler for Windows cross-compilation
i686-w64-mingw32-gcc -static -o build/base85.exe main.c base85.c -Wall -Wextra -O2
i686-w64-mingw32-strip build/base85.exe
echo "Static 32-bit Windows binary built and stripped successfully: build/base85.exe"
