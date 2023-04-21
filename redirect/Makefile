ENABLE_WASM_OPT ?= true

.PHONY: build
build:
	tinygo build -target=wasi -gc=leaking -o redirect.wasm redirect.go
ifeq ($(ENABLE_WASM_OPT),true)
	wasm-opt -Os -o ../components/redirect.wasm redirect.wasm
endif
	rm redirect.wasm
