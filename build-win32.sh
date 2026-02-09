#!/bin/sh

# Build script for 32-bit Windows base85 binary
mkdir -p build

# Use MinGW-w64 32-bit compiler for Windows cross-compilation
# Try to achieve maximum static linking
i686-w64-mingw32-gcc -static -static-libgcc -static-libstdc++ -Wl,-Bstatic -o build/base85.win32.x86.exe main.c base85.c -Wall -Wextra -O2 -lmsvcrt
i686-w64-mingw32-strip build/base85.win32.x86.exe
echo "32-bit Windows binary built and stripped successfully: build/base85.win32.x86.exe"
