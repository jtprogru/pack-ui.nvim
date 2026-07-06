-- Headless test bootstrap. Puts the plugin and plenary on the runtimepath so
-- `PlenaryBustedDirectory` can discover and run the specs. plenary is expected
-- at deps/plenary.nvim (the CI job checks it out there; clone it locally to run
-- the suite by hand).

local root = vim.fn.getcwd()
-- Prepend so this working copy wins over any pack-ui.nvim the developer already
-- has installed (e.g. under ~/.config/nvim/pack/*/start); otherwise require()
-- would load the installed copy and test the wrong code.
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(root .. "/deps/plenary.nvim")

vim.cmd("runtime plugin/plenary.vim")
