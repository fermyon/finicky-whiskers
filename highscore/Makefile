
.PHONY: build
build:
	cargo build --target wasm32-wasi --release
	wasm-opt target/wasm32-wasi/release/highscore.wasm -o ../components/highscore.wasm -Os

.PHONY: serve
serve: build
serve:
	spin up -f spin.toml