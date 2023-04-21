.PHONY: build
build:
	spin build

.PHONY: serve
serve:
	./serve.sh

.PHONY: start-redis
start-redis:
	@docker start fw-redis &>/dev/null || docker run -p 6379:6379 --name fw-redis redis:7 &

.PHONY: stop-redis
stop-redis:
	@docker stop fw-redis &>/dev/null

.PHONY: test-server
test-server:
	./tests/test-server.sh