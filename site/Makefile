SPIN_FILESERVER ?= ../../spin-fileserver

.PHONY: build
build:
	cd $(SPIN_FILESERVER) && cargo build --target wasm32-wasi --release
	wasm-opt -Os -o ../components/fileserver.wasm $(SPIN_FILESERVER)/target/wasm32-wasi/release/spin_static_fs.wasm
