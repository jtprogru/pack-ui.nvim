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
  -- The optional *global* launcher maps registered by `setup()`. `status` and
  -- `update_all` are suffixes appended to `prefix`; set a suffix to `false` to
  -- skip it, or `keymaps = false` to skip them all. They carry `desc`s, so
  -- which-key (if installed) shows them under a "pack-ui" group. Nothing is
  -- mapped unless `setup()` is called.
  keymaps = {
    prefix = "<leader>p",
    status = "s", -- <leader>ps -> :PackStatus
    update_all = "U", -- <leader>pU -> :PackUpdateAll
  },
  -- The buffer-local keys active *inside* the pack-ui float. Each action takes
  -- a key string or a list of them; set one to `false` to unbind it.
  -- Independent of `keymaps`: `keymaps = false` leaves these alone, so the
  -- window is always operable.
  window_keymaps = {
    close = { "q", "<Esc>" },
    toggle_mark = { "<Space>", "<Tab>" },
    mark_all = { "a" },
    update_marked = { "u" }, -- update marked rows (or the row under the cursor)
    update_all = { "U" },
    refresh = { "r", "R" },
    changelog = { "<CR>", "K" }, -- details / changelog for the row under the cursor
  },
}

M.options = vim.deepcopy(M.defaults)

-- Copy each action from `overrides` onto `base`. Window actions are lists,
-- which `tbl_deep_extend` merges by index (overriding `{ "q", "<Esc>" }` with
-- `{ "gq" }` would leave `<Esc>` behind), so each one has to replace its
-- default wholesale.
local function overlay(base, overrides)
  if type(overrides) ~= "table" then
    return
  end
  for action, keys in pairs(overrides) do
    base[action] = keys
  end
end

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, opts)

  local win = vim.deepcopy(M.defaults.window_keymaps)
  -- `keymaps.window` is the pre-0.2 home of the window keys. It still works,
  -- but `window_keymaps` wins per action when both are set.
  local legacy = type(opts.keymaps) == "table" and opts.keymaps.window or nil
  if legacy ~= nil then
    vim.deprecate("keymaps.window", "window_keymaps", "0.3.0", "pack-ui", false)
    overlay(win, legacy)
    M.options.keymaps.window = nil
  end
  overlay(win, opts.window_keymaps)
  M.options.window_keymaps = win
  return M.options
end

-- The buffer-local window keymaps, resolved by `setup()` (or the defaults if
-- it was never called).
function M.window_keymaps()
  return M.options.window_keymaps or M.defaults.window_keymaps
end

return M
