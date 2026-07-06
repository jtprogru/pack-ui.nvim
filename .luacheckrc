-- Luacheck configuration for a Neovim Lua plugin.
std = "lua51"
cache = true
codes = true

-- `vim` is writable, not read-only: the plugin sets buffer/window options via
-- vim.bo[buf].x / vim.wo[win].y, which read_globals would flag as W122.
globals = { "vim" }

-- The test suite uses the busted-style globals that plenary provides.
files["tests/"] = {
  read_globals = { "describe", "it", "before_each", "after_each", "assert" },
}

-- Long descriptive strings and format lines are fine.
max_line_length = 140
