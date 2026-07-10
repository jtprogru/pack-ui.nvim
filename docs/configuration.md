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
    window = {
      close = { "q", "<Esc>" },
      toggle_mark = { "<Space>", "<Tab>" },
      mark_all = { "a" },
      update_marked = { "u" },
      update_all = { "U" },
      refresh = { "r", "R" },
      changelog = { "<CR>", "K" },
    },
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
| `keymaps` | see below | Global launcher keymaps + the in-window `window` keys. `keymaps = false` registers no global maps (the window keys stay). |

## Keymaps

`keymaps` covers two independent groups.

### Global launcher keys

`prefix`, `status`, and `update_all` register optional global maps when `setup()` is called. Each is a suffix appended to `prefix`; set a suffix to `false` to skip it, or `keymaps = false` to skip them all:

```lua
require("pack_ui").setup({
  keymaps = { prefix = "<leader>u", update_all = false },
})
```

See [Automation → Global keymaps & which-key](automation.md#global-keymaps-which-key) for how these surface in which-key.

### In-window keys (`keymaps.window`)

The buffer-local keys active *inside* the float. Each action takes a key string or a list of keys; set one to `false` to unbind it. These stay active even with `keymaps = false` — that only turns off the global launcher maps. The winbar hints follow whatever you bind here.

```lua
require("pack_ui").setup({
  keymaps = {
    window = {
      update_marked = "gu",   -- rebind update to `gu`
      changelog = false,      -- unbind the details/changelog key
    },
  },
})
```

| Action | Default | Description |
| --- | --- | --- |
| `close` | `{ "q", "<Esc>" }` | Close the window. |
| `toggle_mark` | `{ "<Space>", "<Tab>" }` | Toggle the mark on the current row. |
| `mark_all` | `{ "a" }` | Mark / unmark all rows. |
| `update_marked` | `{ "u" }` | Update marked rows (or the row under the cursor). |
| `update_all` | `{ "U" }` | Update all rows with available updates. |
| `refresh` | `{ "r", "R" }` | Re-check remotes. |
| `changelog` | `{ "<CR>", "K" }` | Show changelog / details for the plugin under the cursor. |

## Custom commands

To define your own commands instead of the defaults, set `vim.g.loaded_pack_ui = true` before startup and call the functions yourself:

```lua
require("pack_ui").status()
require("pack_ui").update()
require("pack_ui").update_all()
```
