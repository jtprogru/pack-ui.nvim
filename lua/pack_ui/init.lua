-- pack_ui — a floating-window UI for Neovim's built-in vim.pack.
--
-- One window shows the read-only state of every managed plugin and lets you
-- apply updates pointwise (mark rows, then <CR>) or all at once (U). See
-- README.md for keymaps and behaviour.
--
-- Public API:
--   require("pack_ui").status()      -- read-only overview (no network)
--   require("pack_ui").update()      -- check, then apply what you mark
--   require("pack_ui").update_all()  -- check, then apply everything
--   require("pack_ui").setup(opts)   -- override defaults (see config.lua)

local ui = require("pack_ui.ui")

local M = {}

-- Merge user options and register the optional global keymaps (which-key aware).
-- Calling setup() is optional; the :Pack* commands work without it.
function M.setup(opts)
  local options = require("pack_ui.config").setup(opts)
  require("pack_ui.keymaps").register(options.keymaps)
  -- Opt-in background automation. auto_update supersedes auto_check (it checks
  -- too). Deferred so the fetch never sits on the startup critical path.
  if options.auto_update then
    vim.schedule(require("pack_ui.auto").update)
  elseif options.auto_check then
    vim.schedule(require("pack_ui.auto").check)
  end
  return options
end

M.open = ui.open
M.status = ui.status
M.update = ui.update
M.update_all = ui.update_all

return M
