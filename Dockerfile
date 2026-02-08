# Single-stage Dockerfile for building static base85 binary
FROM alpine:latest

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make

# Set working directory
WORKDIR /app

# Copy source files
COPY *.c *.h Makefile ./

# Build the static binary at runtime (not build time)
# Detect architecture and name accordingly
CMD ["sh", "-c", "mkdir -p build && ARCH=$(uname -m) && if [ \"$ARCH\" = \"aarch64\" ]; then OUTPUT=\"build/base85.arm64\"; else OUTPUT=\"build/base85.x86_64\"; fi && gcc -static -o $OUTPUT main.c base85.c -Wall -Wextra -O2 && strip $OUTPUT && echo \"Static binary built and stripped successfully: $OUTPUT\""]
