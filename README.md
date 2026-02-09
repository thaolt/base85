# Base85 Library & CLI Tool

A lightweight C implementation of Base85 (Ascii85) encoding and decoding with a small portable library and a command-line interface.

## Overview

Base85 is an encoding scheme that represents binary data using ASCII characters. It's more efficient than Base64, using 85 characters instead of 64, resulting in approximately 20% smaller encoded output.

This implementation uses the RFC 1924 character set:
```
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~
```

## Features

- **Library API**: Simple functions for encoding/decoding data in memory (no I/O)
- **Block API**: Encode/decode a single partial block (useful for incremental/stream processing)
- **CLI Tool**: Command-line utility compatible with standard input/output (all I/O lives in the executable)
- **Cross-platform**: Pure C implementation with no external dependencies

## Building

```bash
# Build the executable
make

# Run tests
make test

# Clean build artifacts
make clean
```

The executable will be created as `build/base85`.

## Cross-Platform Builds

The project supports building binaries for different platforms using Docker:

```bash
# Build static binary for Linux x86_64
make linux.x86_64

# Build static binary for Linux ARM64
make linux.arm64

# Build native FreeBSD amd64 binary using QEMU
make freebsd.qemu

# Build binary for Windows 32-bit (x86)
make win32

# Build all release binaries (Linux x86_64, Linux ARM64, FreeBSD amd64, Windows)
make release
```

The Linux binaries are fully static and self-contained. The FreeBSD binary is built natively inside a FreeBSD VM (QEMU). The Windows binary is compatible with modern Windows systems and has minimal dependencies (only core Windows system libraries).

**Binary Naming Convention:**
- `base85.linux.x86_64` - Static Linux binary for x86_64 architecture
- `base85.linux.arm64` - Static Linux binary for ARM64 architecture  
- `base85.freebsd.amd64` - Native FreeBSD binary (built inside a FreeBSD QEMU VM)
- `base85.win32.x86.exe` - Windows binary for 32-bit x86 architecture

## Usage

### Command Line

```bash
# Encode file to stdout
./build/base85 input.txt

# Encode from stdin
cat data.bin | ./build/base85

# Decode from stdin
cat encoded.txt | ./build/base85 -d

# Decode file to stdout
./build/base85 -d encoded.txt

# Show help
./build/base85 --help

# Show version
./build/base85 --version
```

### Library API

```c
#include "base85.h"

// Encode data in memory
unsigned char input[] = {0x48, 0x65, 0x6c, 0x6c, 0x6f}; // "Hello"
char output[100];
size_t encoded_len = base85_encode(input, sizeof(input), output);

// Decode data in memory
unsigned char decoded[100];
size_t decoded_len = base85_decode(output, encoded_len, decoded);

// Block-level (incremental) encoding
char block_out[5];
size_t block_out_len = base85_encode_block(input, 4, block_out);

// Block-level (incremental) decoding
unsigned char block_decoded[4];
size_t block_decoded_len = base85_decode_block(block_out, block_out_len, block_decoded);
```

## API Reference

### Functions

- `size_t base85_encode(const unsigned char* input, size_t input_len, char* output)`
  - Encode binary data to Base85 string
  - Returns number of characters written (excluding null terminator)
  - Output buffer should be at least `input_len * 5 / 4 + 5` bytes

- `size_t base85_decode(const char* input, size_t input_len, unsigned char* output)`
  - Decode Base85 string back to binary data
  - Returns number of bytes written
  - Output buffer should be at least `input_len * 4 / 5 + 4` bytes

- `size_t base85_encode_block(const unsigned char* input, size_t input_len, char* output)`
  - Encode a single block of up to 4 bytes
  - `input_len` must be in the range 1..4
  - Returns number of characters written (1..5)

- `size_t base85_decode_block(const char* input, size_t input_len, unsigned char* output)`
  - Decode a single Base85 block
  - `input_len` must be in the range 1..5
  - Returns number of bytes written

## Testing

The project includes comprehensive tests:

```bash
make test
```

Tests cover:
- Empty string handling
- Simple text round-trip encoding/decoding
- Binary data preservation
- Longer text processing

## Performance Characteristics

- **Encoding**: 4 bytes → 5 characters (25% overhead)
- **Memory**: The CLI processes streams in chunks for efficient processing
- **Speed**: Optimized for both small and large data sets
- **Compatibility**: Works with any binary data including null bytes

## License

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

## Contributing

Feel free to submit issues or pull requests to improve the implementation.
