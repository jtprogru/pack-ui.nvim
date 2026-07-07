# Installation

Requires Neovim 0.12+ (for the built-in `vim.pack`).

## With `vim.pack` itself

```lua
vim.pack.add({ { src = "https://github.com/jtprogru/pack-ui.nvim" } })
```

## As a native package (no manager)

```sh
git clone https://github.com/jtprogru/pack-ui.nvim \
  ~/.config/nvim/pack/local/start/pack-ui.nvim
```

The commands register automatically on startup. Calling [`setup()`](configuration.md) is optional — you only need it to change window options or register the global keymaps.
