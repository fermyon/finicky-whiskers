.PHONY: build
build:
	spin build

.PHONY: serve
serve:
	spin up --sqlite @highscore/migration.sql

.PHONY: test-server
test-server:
	./tests/test-server.sh
