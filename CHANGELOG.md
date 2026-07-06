# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Floating-window UI over Neovim's built-in `vim.pack` (Neovim 0.12+).
- `:PackStatus` — read-only overview with no network access.
- `:PackUpdate` — check for updates and apply the rows you mark (`<CR>`) or all (`U`).
- `:PackUpdateAll` — check and apply every available update automatically.
- In-window keymaps for marking rows, applying updates, re-checking remotes, and viewing changelogs.
- Optional global keymaps under a configurable prefix, discoverable via which-key.
- `setup()` for configuring border, title, window size, and keymaps.

[Unreleased]: https://github.com/jtprogru/pack-ui.nvim/commits/main
