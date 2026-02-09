#!/usr/bin/env sh
set -eu

PROJECT_ROOT=${PROJECT_ROOT:-$(pwd)}
HOST_BUILD_DIR=${HOST_BUILD_DIR:-build}

WORK_DIR="${HOST_BUILD_DIR%/}/freebsd.qemu"

FREEBSD_IMAGE_URL=${FREEBSD_IMAGE_URL:-https://download.freebsd.org/releases/VM-IMAGES/14.3-RELEASE/amd64/Latest/FreeBSD-14.3-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2.xz}
FREEBSD_IMAGE_XZ="$WORK_DIR/$(basename "$FREEBSD_IMAGE_URL")"
FREEBSD_IMAGE_QCOW2="${FREEBSD_IMAGE_XZ%.xz}"

SSH_USER=${FREEBSD_SSH_USER:-freebsd}
SSH_PORT=${FREEBSD_SSH_PORT:-2222}
SSH_PRIVKEY=${FREEBSD_SSH_KEY:-$WORK_DIR/id_ed25519}
SSH_PUBKEY="$SSH_PRIVKEY.pub"

SEED_DIR="$WORK_DIR/seed"
SEED_ISO="$WORK_DIR/seed.iso"

QEMU_LOG="$WORK_DIR/qemu.log"

QEMU_BIN=${QEMU_BIN:-qemu-system-x86_64}
QEMU_MEM=${QEMU_MEM:-2048}
QEMU_SMP=${QEMU_SMP:-2}
QEMU_EXTRA_ARGS=${QEMU_EXTRA_ARGS:-}

GUEST_WORKDIR=${GUEST_WORKDIR:-/tmp/base85-build}
OUTPUT_NAME=${OUTPUT_NAME:-base85.freebsd.amd64}

usage() {
    cat <<EOF
Usage:
  make freebsd.qemu

Environment variables:
  HOST_BUILD_DIR       Host build dir (default: build)
  PROJECT_ROOT         Project root (default: current directory)
  FREEBSD_IMAGE_URL    FreeBSD BASIC-CLOUDINIT qcow2.xz URL to download
  FREEBSD_SSH_USER     SSH username in guest (default: freebsd)
  FREEBSD_SSH_KEY      SSH private key path (default: build/freebsd.qemu/id_ed25519)
  FREEBSD_SSH_PORT     Host forwarded SSH port (default: 2222)
  QEMU_BIN             QEMU binary (default: qemu-system-x86_64)
  QEMU_MEM             RAM in MB (default: 2048)
  QEMU_SMP             vCPUs (default: 2)
  QEMU_EXTRA_ARGS      Extra args appended to QEMU invocation
  GUEST_WORKDIR        Guest work dir (default: /tmp/base85-build)
  OUTPUT_NAME          Artifact name (default: base85.freebsd.amd64)

Notes:
  - This script downloads a FreeBSD cloud-init image, injects an SSH key via a NoCloud seed ISO,
    boots QEMU with user-mode networking and hostfwd, then builds inside the guest.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $1" >&2
        exit 2
    fi
}

need_cmd "$QEMU_BIN"
need_cmd ssh
need_cmd scp
need_cmd ssh-keygen
need_cmd xz

if command -v curl >/dev/null 2>&1; then
    DL="curl -fL --retry 3 -o"
elif command -v wget >/dev/null 2>&1; then
    DL="wget -O"
else
    echo "ERROR: need curl or wget to download FreeBSD image" >&2
    exit 2
fi

if command -v xorriso >/dev/null 2>&1; then
    MKISO="xorriso -as mkisofs"
elif command -v genisoimage >/dev/null 2>&1; then
    MKISO="genisoimage"
elif command -v mkisofs >/dev/null 2>&1; then
    MKISO="mkisofs"
else
    echo "ERROR: need xorriso, genisoimage, or mkisofs to create cloud-init seed ISO" >&2
    exit 2
fi

mkdir -p "$WORK_DIR" "$HOST_BUILD_DIR"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p $SSH_PORT -i $SSH_PRIVKEY"
SCP_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -P $SSH_PORT -i $SSH_PRIVKEY"

if [ ! -f "$SSH_PRIVKEY" ]; then
    ssh-keygen -t ed25519 -N "" -f "$SSH_PRIVKEY" >/dev/null
fi

if [ ! -f "$SSH_PUBKEY" ]; then
    echo "ERROR: missing public key: $SSH_PUBKEY" >&2
    exit 2
fi

if [ ! -f "$FREEBSD_IMAGE_QCOW2" ]; then
    if [ ! -f "$FREEBSD_IMAGE_XZ" ]; then
        echo "Downloading FreeBSD image..." >&2
        if ! $DL "$FREEBSD_IMAGE_XZ" "$FREEBSD_IMAGE_URL" >/dev/null 2>&1; then
            rm -f "$FREEBSD_IMAGE_XZ"
            if ! $DL "$FREEBSD_IMAGE_XZ" "$FREEBSD_IMAGE_URL"; then
                rm -f "$FREEBSD_IMAGE_XZ"
                for url in \
                    "https://download.freebsd.org/releases/VM-IMAGES/14.3-RELEASE/amd64/Latest/FreeBSD-14.3-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2.xz" \
                    "https://download.freebsd.org/releases/VM-IMAGES/14.3-RELEASE/amd64/Latest/FreeBSD-14.3-RELEASE-amd64-BASIC-CLOUDINIT-zfs.qcow2.xz" \
                    "https://download.freebsd.org/releases/VM-IMAGES/14.2-RELEASE/amd64/Latest/FreeBSD-14.2-RELEASE-amd64-BASIC-CLOUDINIT-zfs.qcow2.xz" \
                    "https://download.freebsd.org/releases/VM-IMAGES/15.0-RELEASE/amd64/Latest/FreeBSD-15.0-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2.xz" \
                ; do
                    echo "Retrying with $url" >&2
                    FREEBSD_IMAGE_URL="$url"
                    FREEBSD_IMAGE_XZ="$WORK_DIR/$(basename "$FREEBSD_IMAGE_URL")"
                    FREEBSD_IMAGE_QCOW2="${FREEBSD_IMAGE_XZ%.xz}"
                    if $DL "$FREEBSD_IMAGE_XZ" "$FREEBSD_IMAGE_URL" >/dev/null 2>&1; then
                        break
                    fi
                    rm -f "$FREEBSD_IMAGE_XZ"
                done
            fi
        fi
    fi
    if [ ! -f "$FREEBSD_IMAGE_XZ" ]; then
        echo "ERROR: failed to download FreeBSD image" >&2
        exit 2
    fi
    echo "Decompressing FreeBSD image..." >&2
    xz -dk "$FREEBSD_IMAGE_XZ"
fi

if [ ! -f "$FREEBSD_IMAGE_QCOW2" ]; then
    echo "ERROR: expected qcow2 image missing: $FREEBSD_IMAGE_QCOW2" >&2
    exit 2
fi

mkdir -p "$SEED_DIR"

PUBKEY_CONTENT=$(cat "$SSH_PUBKEY")

cat > "$SEED_DIR/meta-data" <<EOF
instance-id: base85-freebsd-qemu
local-hostname: base85-freebsd-qemu
EOF

cat > "$SEED_DIR/user-data" <<EOF
#cloud-config
users:
  - name: $SSH_USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/sh
    ssh_authorized_keys:
      - $PUBKEY_CONTENT
runcmd:
  - [ sh, -lc, 'sysrc sshd_enable=YES || true' ]
  - [ sh, -lc, 'service sshd onestart || true' ]
EOF

rm -f "$SEED_ISO"
$MKISO -output "$SEED_ISO" -volid cidata -joliet -rock "$SEED_DIR" >/dev/null 2>&1 || \
    $MKISO -o "$SEED_ISO" -V cidata -J -R "$SEED_DIR" >/dev/null 2>&1 || \
    $MKISO -o "$SEED_ISO" -V cidata -J -R "$SEED_DIR"

QEMU_PID=""
cleanup() {
    if [ -n "${QEMU_PID}" ] && kill -0 "${QEMU_PID}" 2>/dev/null; then
        kill "${QEMU_PID}" 2>/dev/null || true
        wait "${QEMU_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

QEMU_ACCEL_ARGS=""
if [ -c /dev/kvm ] && "$QEMU_BIN" -accel help 2>/dev/null | grep -qi kvm; then
    QEMU_ACCEL_ARGS="-enable-kvm -cpu host"
fi

# Boot the VM in the background.
# Using -nographic keeps it headless; serial console goes to stdio.
rm -f "$QEMU_LOG"
"$QEMU_BIN" \
    $QEMU_ACCEL_ARGS \
    -m "$QEMU_MEM" \
    -smp "$QEMU_SMP" \
    -drive "file=$FREEBSD_IMAGE_QCOW2,if=virtio" \
    -drive "file=$SEED_ISO,media=cdrom,readonly=on" \
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    $QEMU_EXTRA_ARGS \
    >"$QEMU_LOG" 2>&1 &
QEMU_PID=$!

# Wait for SSH to become available.
MAX_WAIT=${MAX_WAIT_SECONDS:-600}
SLEEP_STEP=2
ELAPSED=0
while :; do
    if ssh -o ConnectTimeout=5 $SSH_OPTS "$SSH_USER@127.0.0.1" true >/dev/null 2>&1; then
        break
    fi
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "ERROR: Timed out waiting for SSH on 127.0.0.1:$SSH_PORT" >&2
        echo "QEMU log: $QEMU_LOG" >&2
        exit 3
    fi
    sleep "$SLEEP_STEP"
    ELAPSED=$((ELAPSED + SLEEP_STEP))
done

# Create workdir and upload sources.
ssh $SSH_OPTS "$SSH_USER@127.0.0.1" "rm -rf '$GUEST_WORKDIR' && mkdir -p '$GUEST_WORKDIR'"

SOURCES="$PROJECT_ROOT/main.c $PROJECT_ROOT/base85.c $PROJECT_ROOT/base85.h $PROJECT_ROOT/Makefile"
for f in $SOURCES; do
    if [ ! -f "$f" ]; then
        echo "ERROR: missing source file: $f" >&2
        exit 2
    fi
done

# Upload minimal set of files needed for build.
scp $SCP_OPTS \
    $SOURCES \
    "$SSH_USER@127.0.0.1:$GUEST_WORKDIR/" \
    >/dev/null

# Build inside FreeBSD (native toolchain).
ssh $SSH_OPTS "$SSH_USER@127.0.0.1" "set -eu; cd '$GUEST_WORKDIR'; cc -static -O2 -Wall -Wextra -o '$OUTPUT_NAME' main.c base85.c; strip -s '$OUTPUT_NAME' || true"

# Download artifact.
scp $SCP_OPTS \
    "$SSH_USER@127.0.0.1:$GUEST_WORKDIR/$OUTPUT_NAME" \
    "./$HOST_BUILD_DIR/$OUTPUT_NAME" \
    >/dev/null

echo "Native FreeBSD artifact written to ./$HOST_BUILD_DIR/$OUTPUT_NAME"
