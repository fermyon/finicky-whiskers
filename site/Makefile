SPIN_FILESERVER ?= ../../spin-fileserver
ENABLE_WASM_OPT ?= true

.PHONY: build
build:
	cd $(SPIN_FILESERVER) && cargo build --target wasm32-wasi --release
ifeq ($(ENABLE_WASM_OPT),true)
	wasm-opt -Os -o ../components/fileserver.wasm $(SPIN_FILESERVER)/target/wasm32-wasi/release/spin_static_fs.wasm
endif