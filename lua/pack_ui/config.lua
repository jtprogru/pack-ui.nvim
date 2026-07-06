-- User-facing options, merged from `require("pack_ui").setup(opts)`.

local M = {}

M.defaults = {
  border = "rounded",
  title = " vim.pack ",
  -- Window size: a ratio of the editor grid, capped by `max_width`.
  max_width = 100,
  width_ratio = 0.9,
  height_ratio = 0.85,
  -- Background automation, run from `setup()`. Both are off by default: nothing
  -- touches the network or updates plugins unless you opt in.
  --   auto_check  -> on setup, fetch remotes in the background and notify if any
  --                  plugin has updates (no window, no changes applied).
  --   auto_update -> on setup, fetch and apply every available update
  --                  automatically. Implies a check; supersedes `auto_check`.
  auto_check = false,
  auto_update = false,
  -- Global keymaps registered by `setup()`. Each entry is a suffix appended to
  -- `prefix`; set a suffix to `false` to skip it, or `keymaps = false` to skip
  -- them all. They carry `desc`s, so which-key (if installed) shows them under
  -- a "pack-ui" group. Nothing is mapped unless `setup()` is called.
  keymaps = {
    prefix = "<leader>p",
    status = "s", -- <leader>ps -> :PackStatus
    update_all = "U", -- <leader>pU -> :PackUpdateAll
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

return M
