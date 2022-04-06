
.PHONY: build
build:
	cargo build --target wasm32-wasi --release

.PHONY: serve
serve: build
serve:
	spin up -f ../spin.toml