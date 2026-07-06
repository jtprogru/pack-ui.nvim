.PHONY: test lint format deps

# Where the test suite expects plenary.nvim (see tests/minimal_init.lua).
PLENARY := deps/plenary.nvim

# Clone plenary.nvim locally so the tests can run.
deps:
	@test -d $(PLENARY) || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY)

# Run the full spec suite headless, one spec per fresh Neovim instance.
test: deps
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua', sequential = true }"

# Static analysis.
lint:
	luacheck lua tests

# Check formatting; run `stylua .` to apply.
format:
	stylua --check .
