# Usage

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

Every key here is configurable via `keymaps.window` — see [Configuration → Keymaps](configuration.md#keymaps).

## Reading the list

A column header row labels every field: a mark box, a status glyph, `●`/`○` (active in this session or not), the plugin name, the revision, and a trailing version/status column.

Rows that have an update are grouped under an `── updates available ──` section at the top of the list (with the rest under `── up to date ──`) after a check, and each is shown in bold.

An updatable row spells the change out as `current → latest` — a semver tag for version-tracked plugins (e.g. `v0.9.0 → v1.0.0`), a short sha otherwise — followed by the `N new` commit count.
