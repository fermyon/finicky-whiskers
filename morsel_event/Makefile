
.PHONY: build
build:
	cargo build --target wasm32-wasi --release
	wasm-opt target/wasm32-wasi/release/morsel_event.wasm -o ../components/morsel_event.wasm -Os

.PHONY: serve
serve: build
serve:
	spin up -f spin.toml