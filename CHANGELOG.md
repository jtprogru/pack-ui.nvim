# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-07-07

### Fixed

- `:PackStatus` now reflects updates found by a background `auto_check`. The headless check and the windowed UI shared no state, so plugins with pending updates were left unhighlighted even after the "updates available" notification. An in-memory cache now bridges the two: the background check stores its results and `PackStatus` surfaces them on open, without a second network round-trip. A live re-check (`r` / `:PackUpdate`) still supersedes the cache.

## [0.1.0] - 2026-07-07

### Added

- Floating-window UI over Neovim's built-in `vim.pack` (Neovim 0.12+).
- `:PackStatus` — read-only overview with no network access.
- `:PackUpdate` — check for updates and apply the rows you mark (`<CR>`) or all (`U`).
- `:PackUpdateAll` — check and apply every available update automatically.
- In-window keymaps for marking rows, applying updates, re-checking remotes, and viewing changelogs.
- Optional global keymaps under a configurable prefix, discoverable via which-key.
- `auto_check` — on `setup()`, check remotes in the background and notify if updates exist (off by default).
- `auto_update` — on `setup()`, fetch and apply every available update automatically (off by default).
- `setup()` for configuring border, title, window size, and keymaps.

### Changed

- Reworked the plugin list to read like Mason: a column header row (`Plugin` / `Revision` / `Version / status`) labels every field, and updatable plugins are grouped under an `── updates available ──` section at the top of the list (with the rest under `── up to date ──`) after a check.
- Updatable rows now show the update explicitly as `current → latest` — a semver tag for version-tracked plugins (e.g. `v0.9.0 → v1.0.0`), a short sha otherwise — alongside the new-commit count, and the whole row is rendered in bold so available updates stand out at a glance.
- Dropped the global `<leader>pu` (`:PackUpdate`) keymap: marking rows only makes sense inside the window, so the prefix binds just `s` (status) and `U` (update all). `:PackUpdate` is unchanged.

[Unreleased]: https://github.com/jtprogru/pack-ui.nvim/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/jtprogru/pack-ui.nvim/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/jtprogru/pack-ui.nvim/releases/tag/v0.1.0
