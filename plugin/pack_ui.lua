-- Register the user commands. Guarded so it runs once, and skipped on Neovim
-- builds without vim.pack. Set `vim.g.loaded_pack_ui = true` before startup to
-- opt out and define your own commands against require("pack_ui").

if vim.g.loaded_pack_ui then
  return
end
vim.g.loaded_pack_ui = true

if type(vim.pack) ~= "table" then
  return
end

local command = vim.api.nvim_create_user_command

command("PackStatus", function()
  require("pack_ui").status()
end, { desc = "vim.pack: floating status window (press r to check updates)" })

command("PackUpdate", function()
  require("pack_ui").update()
end, { desc = "vim.pack: floating update UI (mark rows, u to apply)" })

command("PackUpdateAll", function()
  require("pack_ui").update_all()
end, { desc = "vim.pack: update all plugins (floating window)" })
