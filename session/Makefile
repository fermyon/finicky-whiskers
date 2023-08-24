RUBY_FLAVOR = head-wasm32-unknown-wasi-full

.PHONY: build
build: $(RUBY_FLAVOR) .gem
	wasi-vfs pack $(RUBY_FLAVOR)/usr/local/bin/ruby \
		--mapdir /lib::./lib \
		--mapdir /.gem::./.gem \
		--mapdir /usr::./$(RUBY_FLAVOR)/usr \
		-o ../components/session.wasm

$(RUBY_FLAVOR):
	curl -fsLO https://github.com/ruby/ruby.wasm/releases/download/ruby-head-wasm-wasi-0.3.0/ruby-$(RUBY_FLAVOR).tar.gz
	tar -xf ruby-$(RUBY_FLAVOR).tar.gz

.gem:
	GEM_HOME=.gem bundle install

clean:
	rm -rf .gem ./$(RUBY_FLAVOR) ruby-$(RUBY_FLAVOR).tar.gz

.PHONY: serve
serve: ruby .gem
	RUST_LOG=spin=info,wagi=info spin up --file spin.toml
