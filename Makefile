BUILD_DIR ?= build

$(BUILD_DIR)/base85: $(BUILD_DIR) main.c base85.c
	gcc -o $(BUILD_DIR)/base85 main.c base85.c -Wall -Wextra -O2

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: clean test base85 static static-arm64

base85: $(BUILD_DIR)/base85

static: $(BUILD_DIR)
	docker build -t base85-static-builder .
	docker run --rm -v $(PWD)/$(BUILD_DIR):/app/build base85-static-builder
	docker rmi base85-static-builder

static-arm64: $(BUILD_DIR)
	docker buildx build --platform linux/arm64 -t base85-static-builder-arm64 . --load
	docker run --rm --platform linux/arm64 -v $(PWD)/$(BUILD_DIR):/app/build base85-static-builder-arm64
	docker rmi base85-static-builder-arm64

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
	@echo "Test 3: Zero block (should encode as 'z')"
	@printf '\0\0\0\0' | $(BUILD_DIR)/base85 > $(BUILD_DIR)/test3.out
	@grep -q "^z$$" $(BUILD_DIR)/test3.out
	@echo "✓ Zero block test passed"
	@echo ""
	@echo "Test 4: Binary data"
	@printf '\x00\x01\x02\x03\x04\x05' | $(BUILD_DIR)/base85 | $(BUILD_DIR)/base85 -d > $(BUILD_DIR)/test4.out
	@printf '\x00\x01\x02\x03\x04\x05' > $(BUILD_DIR)/test4.exp
	@cmp $(BUILD_DIR)/test4.out $(BUILD_DIR)/test4.exp
	@echo "✓ Binary data round-trip test passed"
	@echo ""
	@echo "Test 5: Longer text"
	@printf "The quick brown fox jumps over the lazy dog" | $(BUILD_DIR)/base85 | $(BUILD_DIR)/base85 -d > $(BUILD_DIR)/test5.out
	@printf "The quick brown fox jumps over the lazy dog" > $(BUILD_DIR)/test5.exp
	@cmp $(BUILD_DIR)/test5.out $(BUILD_DIR)/test5.exp
	@echo "✓ Longer text round-trip test passed"
	@echo ""
	@echo "All tests passed!"
	@rm -f $(BUILD_DIR)/test*.out $(BUILD_DIR)/test*.exp

clean:
	rm -rf $(BUILD_DIR)