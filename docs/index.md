# pack-ui.nvim

A floating-window UI for Neovim's built-in [`vim.pack`](https://neovim.io/doc/user/pack.html) plugin manager (Neovim 0.12+).

One window shows the read-only state of every managed plugin and lets you apply updates **pointwise** (mark the rows you want, then `<CR>`) or **all at once** (`U`).

## Why

`vim.pack` ships two update flows: `vim.pack.update()` opens a review buffer in a separate tabpage, and `vim.pack.update(nil, { force = true })` updates everything with no review. This plugin puts both — plus a status overview — behind a single, mark-driven floating window.

Update *detection* (which plugins have new commits, and the changelog) is computed with plain `git`, because `vim.pack` exposes no API for it without opening its tabpage buffer. Detection is display-only and best-effort; the actual apply always goes through `vim.pack.update(names, { force = true })`, which owns version resolution and the lockfile.

## At a glance

| | |
| --- | --- |
| **Requires** | Neovim 0.12+ (`vim.pack`) |
| **Commands** | `:PackStatus`, `:PackUpdate`, `:PackUpdateAll` |
| **Network** | Nothing touches the network unless you ask (or opt into [automation](automation.md)) |
| **Setup** | Optional — commands register on startup |

## Next steps

- [Installation](installation.md) — add it with `vim.pack` or as a native package.
- [Usage](usage.md) — the three commands and the in-window keymaps.
- [Configuration](configuration.md) — `setup()` options.
- [Automation](automation.md) — opt-in `auto_check` / `auto_update`.
