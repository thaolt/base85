# base85 - Base85 encoding/decoding utility
# Copyright (C) 2026 thaolt@songphi.com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

# Single-stage Dockerfile for building static base85 binary
FROM alpine:latest

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make

# Set working directory
WORKDIR /app

# Copy source files and Makefile
COPY *.c *.h Makefile ./

# Create build script to be executed at runtime
RUN cat > build.sh << 'EOF'
#!/bin/sh
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
EOF

RUN chmod +x build.sh
CMD ["./build.sh"]
