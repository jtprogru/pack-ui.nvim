# Automation

## Automatic checks & updates

Both are **off by default** — nothing touches the network or changes plugins unless you opt in via `setup()`:

- `auto_check = true` — on startup, fetch remotes in the background and notify you if any plugin has updates. No window opens and nothing is applied; run `:PackUpdate` when you want to review them.
- `auto_update = true` — on startup, fetch and apply every available update automatically (a `:restart` loads the new code). This implies a check, so it supersedes `auto_check`.

The work is deferred off the startup critical path, and the fetch itself runs asynchronously.

```lua
require("pack_ui").setup({
  auto_check = true,   -- notify me at startup when updates exist
  -- auto_update = true,  -- or: just apply everything
})
```

## Global keymaps & which-key

Calling `setup()` registers the global keymaps (nothing is mapped without it). Each carries a description, so if [which-key](https://github.com/folke/which-key.nvim) is installed they show up under a `pack-ui` group when you press the prefix — and the in-window keys (`<Space>`, `a`, `u`, `U`, `r`, `<CR>`, `K`, `q`) appear in which-key too, since they're documented buffer-local maps.

There is deliberately no global keymap for `:PackUpdate`: marking rows only makes sense once the window is open, so `<leader>p` binds only `s` (status) and `U` (update all). Use `:PackUpdate` — or open with `<leader>ps` and mark rows there.
