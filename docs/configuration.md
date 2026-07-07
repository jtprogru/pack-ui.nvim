# Configuration

`setup()` is optional. Call it to change window options or register the global keymaps.

## Defaults

```lua
require("pack_ui").setup({
  border = "rounded",   -- any nvim_open_win border
  title = " vim.pack ",
  max_width = 100,
  width_ratio = 0.9,
  height_ratio = 0.85,
  auto_check = false,   -- on setup, check remotes and notify if updates exist
  auto_update = false,  -- on setup, apply every available update automatically
  keymaps = {
    prefix = "<leader>p",
    status = "s",        -- <leader>ps -> :PackStatus
    update_all = "U",    -- <leader>pU -> :PackUpdateAll
  },
})
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `border` | `"rounded"` | Any `nvim_open_win` border style. |
| `title` | `" vim.pack "` | Window title. |
| `max_width` | `100` | Hard cap on the window width in columns. |
| `width_ratio` | `0.9` | Window width as a ratio of the editor grid (capped by `max_width`). |
| `height_ratio` | `0.85` | Window height as a ratio of the editor grid. |
| `auto_check` | `false` | On `setup()`, check remotes in the background and notify if updates exist. See [Automation](automation.md). |
| `auto_update` | `false` | On `setup()`, fetch and apply every available update automatically. See [Automation](automation.md). |
| `keymaps` | see below | Global keymaps registered by `setup()`, or `false` to register none. |

## Keymaps

Each `keymaps` entry is a suffix appended to `prefix`. Set a suffix to `false` to skip it, or `keymaps = false` to skip them all:

```lua
require("pack_ui").setup({
  keymaps = { prefix = "<leader>u", update_all = false },
})
```

See [Automation → Global keymaps & which-key](automation.md#global-keymaps-which-key) for how these surface in which-key.

## Custom commands

To define your own commands instead of the defaults, set `vim.g.loaded_pack_ui = true` before startup and call the functions yourself:

```lua
require("pack_ui").status()
require("pack_ui").update()
require("pack_ui").update_all()
```
