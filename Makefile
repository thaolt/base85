BUILD_DIR ?= build

FREEBSD_IMAGE_URL ?= https://download.freebsd.org/releases/VM-IMAGES/14.3-RELEASE/amd64/Latest/FreeBSD-14.3-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2.xz
FREEBSD_SSH_USER ?= freebsd
FREEBSD_SSH_KEY ?=
FREEBSD_SSH_PORT ?= 2222
QEMU_BIN ?= qemu-system-x86_64
QEMU_MEM ?= 2048
QEMU_SMP ?= 2
QEMU_EXTRA_ARGS ?=

$(BUILD_DIR)/base85: $(BUILD_DIR) main.c base85.c
	gcc -o $(BUILD_DIR)/base85 main.c base85.c -Wall -Wextra -O2

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: clean test base85 linux.x86_64 linux.arm64 freebsd.qemu win32 wasm release

base85: $(BUILD_DIR)/base85

linux.x86_64: $(BUILD_DIR)
	docker build -t base85-linux-x86_64-builder .
	docker run --rm -v $(PWD)/$(BUILD_DIR):/app/build base85-linux-x86_64-builder
	docker rmi base85-linux-x86_64-builder

linux.arm64: $(BUILD_DIR)
	docker buildx build --platform linux/arm64 -t base85-linux-arm64-builder . --load
	docker run --rm --platform linux/arm64 -v $(PWD)/$(BUILD_DIR):/app/build base85-linux-arm64-builder
	docker rmi base85-linux-arm64-builder

freebsd.qemu: $(BUILD_DIR)
	PROJECT_ROOT="$(PWD)" HOST_BUILD_DIR="$(BUILD_DIR)" \
	FREEBSD_IMAGE_URL="$(FREEBSD_IMAGE_URL)" \
	FREEBSD_SSH_USER="$(FREEBSD_SSH_USER)" \
	FREEBSD_SSH_KEY="$(FREEBSD_SSH_KEY)" \
	FREEBSD_SSH_PORT="$(FREEBSD_SSH_PORT)" \
	QEMU_BIN="$(QEMU_BIN)" \
	QEMU_MEM="$(QEMU_MEM)" \
	QEMU_SMP="$(QEMU_SMP)" \
	QEMU_EXTRA_ARGS="$(QEMU_EXTRA_ARGS)" \
	sh ./scripts/freebsd_qemu_build.sh

win32: $(BUILD_DIR)
	docker build -f Dockerfile.win32 -t base85-win32-builder .
	docker run --rm -v $(PWD)/$(BUILD_DIR):/app/build base85-win32-builder
	docker rmi base85-win32-builder

wasm: $(BUILD_DIR)
	@echo "Building WASM library (requires lld package for wasm-ld linker)..."
	@if command -v wasm-ld >/dev/null 2>&1; then \
		clang --target=wasm32-unknown-unknown --no-standard-libraries -Wl,--no-entry -Wl,--export-all -o $(BUILD_DIR)/base85.wasm base85.c; \
		echo "WASM library built: $(BUILD_DIR)/base85.wasm"; \
	else \
		echo "wasm-ld not found. Installing lld package..."; \
		echo "Run: sudo apt install lld"; \
		clang --target=wasm32-unknown-unknown --no-standard-libraries -c base85.c -o $(BUILD_DIR)/base85.wasm.o; \
		echo "Object file created: $(BUILD_DIR)/base85.wasm.o (needs wasm-ld to link)"; \
	fi

release: $(BUILD_DIR) linux.x86_64 linux.arm64 freebsd.qemu win32 wasm
	@echo "All release binaries built successfully!"
	@ls -la $(BUILD_DIR)/

test: $(BUILD_DIR)/base85
	@echo "Running base85 tests..."
	@echo "Test 1: Empty string"
	@printf "" | $(BUILD_DIR)/base85 > $(BUILD_DIR)/test1.out
	@printf "" > $(BUILD_DIR)/test1.exp
	@cmp $(BUILD_DIR)/test1.out $(BUILD_DIR)/test1.exp
	@echo "✓ Empty string test passed"
	@echo ""
	@echo "Test 2: Simple text"
	@printf "Hello" | $(BUILD_DIR)/base85 | $(BUILD_DIR)/base85 -d > $(BUILD_DIR)/test2.out
	@printf "Hello" > $(BUILD_DIR)/test2.exp
	@cmp $(BUILD_DIR)/test2.out $(BUILD_DIR)/test2.exp
	@echo "✓ Simple text round-trip test passed"
	@echo ""
	@echo "Test 3: Binary data"
	@printf '\x00\x01\x02\x03\x04\x05' | $(BUILD_DIR)/base85 | $(BUILD_DIR)/base85 -d > $(BUILD_DIR)/test3.out
	@printf '\x00\x01\x02\x03\x04\x05' > $(BUILD_DIR)/test3.exp
	@cmp $(BUILD_DIR)/test3.out $(BUILD_DIR)/test3.exp
	@echo "✓ Binary data round-trip test passed"
	@echo ""
	@echo "Test 4: Longer text"
	@printf "The quick brown fox jumps over the lazy dog" | $(BUILD_DIR)/base85 | $(BUILD_DIR)/base85 -d > $(BUILD_DIR)/test4.out
	@printf "The quick brown fox jumps over the lazy dog" > $(BUILD_DIR)/test4.exp
	@cmp $(BUILD_DIR)/test4.out $(BUILD_DIR)/test4.exp
	@echo "✓ Longer text round-trip test passed"
	@echo ""
	@echo "Test 5: Python compatibility decode"
	@$(BUILD_DIR)/base85 -d testdata/2945347.enc > $(BUILD_DIR)/test5.out
	@cmp $(BUILD_DIR)/test5.out testdata/2945347.dec
	@echo "✓ Python compatibility decode test passed"
	@echo ""
	@echo "Test 6: Python compatibility encode"
	@$(BUILD_DIR)/base85 testdata/2945347.dec > $(BUILD_DIR)/test6.out
	@cmp $(BUILD_DIR)/test6.out testdata/2945347.enc
	@echo "✓ Python compatibility encode test passed"
	@echo ""
	@echo "All tests passed!"
	@rm -f $(BUILD_DIR)/test*.out $(BUILD_DIR)/test*.exp

clean:
	rm -rf $(BUILD_DIR)