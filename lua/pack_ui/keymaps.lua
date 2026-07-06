-- Optional global keymaps, registered from `setup()` (see config.lua). Kept
-- separate from the in-window buffer-local maps in pack_ui.ui: these are the
-- entry points that open the window, and they exist only when the user opts in
-- by calling setup(). Every map carries a `desc`, so which-key surfaces them.

local ui = require("pack_ui.ui")

local M = {}

-- Register the global keymaps described by `km` (the resolved config.keymaps).
-- Passing `false`/`nil` registers nothing. If which-key is installed, also add a
-- named group so the prefix reads nicely in its popup.
function M.register(km)
  if not km then
    return
  end
  local prefix = km.prefix or ""

  local defs = {
    { km.status, ui.status, "pack-ui: status" },
    { km.update, ui.update, "pack-ui: update (mark rows)" },
    { km.update_all, ui.update_all, "pack-ui: update all" },
  }
  for _, d in ipairs(defs) do
    local suffix, fn, desc = d[1], d[2], d[3]
    if suffix then
      vim.keymap.set("n", prefix .. suffix, fn, { desc = desc, silent = true })
    end
  end

  if prefix ~= "" then
    local ok, wk = pcall(require, "which-key")
    if ok then
      -- which-key v3 spec. Wrapped in pcall so an older/newer API can't break
      -- setup(); the keymaps above already work without which-key.
      pcall(wk.add, { { prefix, group = "pack-ui" } })
    end
  end
end

return M
