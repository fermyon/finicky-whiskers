.PHONY: build
build:
	tinygo build -wasm-abi=generic -target=wasi -gc=leaking -o redirect.wasm redirect.go
	wasm-opt -Os -o ../components/redirect.wasm redirect.wasm
	rm redirect.wasm