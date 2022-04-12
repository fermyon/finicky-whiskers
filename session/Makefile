RUBY_FLAVOR = head-wasm32-unknown-wasi-full

.PHONY: build
build: ruby .gem

.gem:
	GEM_HOME=.gem bundle install

ruby:
	curl -fsLO https://github.com/ruby/ruby.wasm/releases/download/2022-04-04-a/ruby-$(RUBY_FLAVOR).tar.gz
	tar -xf ruby-$(RUBY_FLAVOR).tar.gz
	rm ruby-$(RUBY_FLAVOR).tar.gz
	mv $(RUBY_FLAVOR) ruby
	cp ruby/usr/local/bin/ruby ruby.wasm

clean:
	rm -rf .gem ruby ruby-$(RUBY_FLAVOR).tar.gz

.PHONY: serve
serve: ruby .gem
	RUST_LOG=spin=info,wagi=info spin up --file spin.toml
