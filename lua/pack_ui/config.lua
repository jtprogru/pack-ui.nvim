-- User-facing options, merged from `require("pack_ui").setup(opts)`.

local M = {}

M.defaults = {
  border = "rounded",
  title = " vim.pack ",
  -- Window size: a ratio of the editor grid, capped by `max_width`.
  max_width = 100,
  width_ratio = 0.9,
  height_ratio = 0.85,
  -- Stacking order of the float, passed straight to `nvim_open_win`. 50 is
  -- Neovim's default for floats; lower it (e.g. 1) if a GUI like Neovide draws
  -- the window in front of everything else. See issue #1.
  zindex = 50,
  -- Background automation, run from `setup()`. Both are off by default: nothing
  -- touches the network or updates plugins unless you opt in.
  --   auto_check  -> on setup, fetch remotes in the background and notify if any
  --                  plugin has updates (no window, no changes applied).
  --   auto_update -> on setup, fetch and apply every available update
  --                  automatically. Implies a check; supersedes `auto_check`.
  auto_check = false,
  auto_update = false,
  -- Keymaps. Two independent groups:
  --  * `prefix`/`status`/`update_all` -> the optional *global* launcher maps
  --    registered by `setup()`. Each is a suffix appended to `prefix`; set a
  --    suffix to `false` to skip it, or `keymaps = false` to skip them all.
  --    They carry `desc`s, so which-key (if installed) shows them under a
  --    "pack-ui" group. Nothing is mapped unless `setup()` is called.
  --  * `window` -> the buffer-local keys active *inside* the pack-ui float.
  --    Each action takes a key string or a list of them; set one to `false`
  --    to unbind it. These stay active even with `keymaps = false` (that only
  --    disables the global launcher maps) so the window is always operable.
  keymaps = {
    prefix = "<leader>p",
    status = "s", -- <leader>ps -> :PackStatus
    update_all = "U", -- <leader>pU -> :PackUpdateAll
    window = {
      close = { "q", "<Esc>" },
      toggle_mark = { "<Space>", "<Tab>" },
      mark_all = { "a" },
      update_marked = { "u" }, -- update marked rows (or the row under the cursor)
      update_all = { "U" },
      refresh = { "r", "R" },
      changelog = { "<CR>", "K" }, -- details / changelog for the row under the cursor
    },
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, opts)
  -- `window` holds list-valued actions, which `tbl_deep_extend` merges by index
  -- (overriding `{ "q", "<Esc>" }` with `{ "gq" }` would leave `<Esc>` behind).
  -- Re-apply the user's window overrides per action so each one replaces its
  -- default wholesale.
  local user_window = type(opts.keymaps) == "table" and opts.keymaps.window or nil
  if user_window then
    local win = vim.deepcopy(M.defaults.keymaps.window)
    for action, keys in pairs(user_window) do
      win[action] = keys
    end
    M.options.keymaps.window = win
  end
  return M.options
end

-- The buffer-local window keymaps, resilient to `keymaps = false` (which only
-- turns off the global launcher maps): falls back to the window defaults.
function M.window_keymaps()
  local km = M.options.keymaps
  return (type(km) == "table" and km.window) or M.defaults.keymaps.window
end

return M
