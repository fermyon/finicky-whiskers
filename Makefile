.PHONY: build
build:
	spin build

.PHONY: serve
serve:
	./serve.sh

.PHONY: test-server
test-server:
	./tests/test-server.sh
