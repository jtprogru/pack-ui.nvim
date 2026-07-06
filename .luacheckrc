-- Luacheck configuration for a Neovim Lua plugin.
std = "lua51"
cache = true
codes = true

-- Neovim injects the global `vim`.
read_globals = { "vim" }

-- The test suite uses the busted-style globals that plenary provides.
files["tests/"] = {
  read_globals = { "describe", "it", "before_each", "after_each", "assert" },
}

-- Long descriptive strings and format lines are fine.
max_line_length = 140
