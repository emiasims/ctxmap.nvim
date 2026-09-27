.PHONY: test doc all
all: test docs

docs: doc/ctxmap.txt
test: deps/mini.nvim
	nvim --headless --clean -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

test.%: deps/mini.nvim
	nvim --headless --clean -u ./scripts/minimal_init.lua -c "lua RunFiles('$*')"

clean:
	rm -f doc/ctxmap.txt
	rm -rf deps

doc/ctxmap.txt: deps/mini.nvim
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua require('mini.doc').generate()"

deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@
