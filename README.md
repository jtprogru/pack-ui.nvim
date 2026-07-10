# pack-ui.nvim

A floating-window UI for Neovim's built-in [`vim.pack`](https://neovim.io/doc/user/pack.html) plugin manager (Neovim 0.12+).

One window shows the read-only state of every managed plugin and lets you apply updates **pointwise** (mark the rows you want, then `u`) or **all at once** (`U`).

📖 **Documentation:** <https://jtprogru.github.io/pack-ui.nvim/>

## Why

`vim.pack` ships two update flows: `vim.pack.update()` opens a review buffer in a separate tabpage, and `vim.pack.update(nil, { force = true })` updates everything with no review. This plugin puts both — plus a status overview — behind a single, mark-driven floating window.

Update *detection* (which plugins have new commits, and the changelog) is computed with plain `git`, because `vim.pack` exposes no API for it without opening its tabpage buffer. Detection is display-only and best-effort; the actual apply always goes through `vim.pack.update(names, { force = true })`, which owns version resolution and the lockfile.

## Commands

| Command | Behaviour |
| --- | --- |
| `:PackStatus` | Read-only overview, no network. Press `r` inside to check remotes. |
| `:PackUpdate` | Opens the window and checks for updates; you apply what you mark. |
| `:PackUpdateAll` | Opens the window, checks, and applies every available update. |

## Keymaps (inside the window)

| Key | Action |
| --- | --- |
| `<Space>` / `<Tab>` | Toggle the mark on the current row |
| `a` | Mark / unmark all |
| `u` | Update marked rows (or the row under the cursor) |
| `U` | Update all rows with available updates |
| `r` | Re-check remotes |
| `<CR>` / `K` | Show changelog / details for the plugin under the cursor |
| `q` / `<Esc>` | Close |

Every in-window key is configurable via `keymaps.window` — see [Configuration](#configuration).

A column header row labels every field: a mark box, a status glyph, `●`/`○` (active in this session or not), the plugin name, the revision, and a trailing version/status column. Rows that have an update are grouped under an `── updates available ──` section at the top of the list (with the rest under `── up to date ──`) after a check, and each is shown in bold. An updatable row spells the change out as `current → latest` — a semver tag for version-tracked plugins (e.g. `v0.9.0 → v1.0.0`), a short sha otherwise — followed by the `N new` commit count.

## Install

Requires Neovim 0.12+ (`vim.pack`).

With `vim.pack` itself:

```lua
vim.pack.add({ { src = "https://github.com/jtprogru/pack-ui.nvim" } })
```

Or as a native package (no manager):

```sh
git clone https://github.com/jtprogru/pack-ui.nvim \
  ~/.config/nvim/pack/local/start/pack-ui.nvim
```

The commands register automatically on startup. `setup()` is optional.

## Configuration

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
    -- Buffer-local keys inside the float. Each takes a string or a list of
    -- keys; set one to `false` to unbind it. These stay active even with
    -- `keymaps = false` (that only turns off the global maps above).
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

## Automatic checks & updates

Both are **off by default** — nothing touches the network or changes plugins unless you opt in via `setup()`:

- `auto_check = true` — on startup, fetch remotes in the background and notify you if any plugin has updates. No window opens and nothing is applied; run `:PackUpdate` when you want to review them.
- `auto_update = true` — on startup, fetch and apply every available update automatically (a `:restart` loads the new code). This implies a check, so it supersedes `auto_check`.

The work is deferred off the startup critical path, and the fetch itself runs asynchronously.

## Global keymaps & which-key

Calling `setup()` registers the global keymaps above (nothing is mapped without it). Each carries a description, so if [which-key](https://github.com/folke/which-key.nvim) is installed they show up under a `pack-ui` group when you press the prefix — and the in-window keys (`<Space>`, `a`, `u`, `U`, `r`, `<CR>`, `K`, `q`) appear in which-key too, since they're documented buffer-local maps.

There is deliberately no global keymap for `:PackUpdate`: marking rows only makes sense once the window is open, so `<leader>p` binds only `s` (status) and `U` (update all). Use `:PackUpdate` — or open with `<leader>ps` and mark rows there.

Set an individual entry to `false` to skip it, or `keymaps = false` to register none:

```lua
require("pack_ui").setup({
  keymaps = { prefix = "<leader>u", update_all = false },
})
```

To define your own commands instead of the defaults, set `vim.g.loaded_pack_ui = true` before startup and call `require("pack_ui").status()` / `.update()` / `.update_all()` yourself.
