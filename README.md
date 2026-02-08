# Base85 Library & CLI Tool

A lightweight C implementation of Base85 (Ascii85) encoding and decoding with both library functions and a command-line interface.

## Overview

Base85 is an encoding scheme that represents binary data using ASCII characters. It's more efficient than Base64, using 85 characters instead of 64, resulting in approximately 20% smaller encoded output.

This implementation uses the Z85 character set:
```
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~
```

## Features

- **Library API**: Simple functions for encoding/decoding data in memory
- **Stream API**: Functions for processing large files without loading everything into memory
- **CLI Tool**: Command-line utility compatible with standard input/output
- **Special Optimization**: Zero blocks (4 null bytes) are encoded as single 'z' character
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

// Stream processing (for large files)
FILE* input = fopen("data.bin", "rb");
FILE* output = fopen("encoded.txt", "w");
base85_encode_stream(input, output);
fclose(input);
fclose(output);
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

- `void base85_encode_stream(FILE* input, FILE* output)`
  - Encode data from input stream to output stream
  - Processes data in chunks for memory efficiency

- `void base85_decode_stream(FILE* input, FILE* output)`
  - Decode data from input stream to output stream
  - Processes data in chunks for memory efficiency

## Testing

The project includes comprehensive tests:

```bash
make test
```

Tests cover:
- Empty string handling
- Simple text round-trip encoding/decoding
- Zero block optimization (encodes as 'z')
- Binary data preservation
- Longer text processing

## Performance Characteristics

- **Encoding**: 4 bytes → 5 characters (25% overhead)
- **Memory**: Stream functions use 1KB buffers for efficient processing
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
