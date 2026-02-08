# Single-stage Dockerfile for building static base85 binary
FROM alpine:latest

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make

# Set working directory
WORKDIR /app

# Copy source files and build script
COPY *.c *.h Makefile build-static.sh ./

# Make build script executable and run it
RUN chmod +x build-static.sh
CMD ["./build-static.sh"]
