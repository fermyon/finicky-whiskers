ENABLE_WASM_OPT ?= true

.PHONY: build
build:
	cargo build --target wasm32-wasi --release
ifeq ($(ENABLE_WASM_OPT),true)
	wasm-opt target/wasm32-wasi/release/reset.wasm -o ../components/reset.wasm -Os
endif