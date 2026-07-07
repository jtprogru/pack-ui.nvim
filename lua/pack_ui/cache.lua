-- Shared, in-memory cache of the last computed update-check results, keyed by
-- plugin name. The background auto-check (auto.lua) writes here so the windowed
-- UI (ui.lua) can reflect known updates the moment PackStatus opens, without a
-- second network round-trip. The UI writes back after any of its own checks, so
-- whichever ran last is the source of truth. Best-effort and point-in-time: it
-- lives for the session only, and `r` in the UI always supersedes it.

local M = {}

-- The check-computed fields git.check fills in; everything else on a plugin row
-- (src, active, rev, selected) is re-derived fresh from vim.pack on each open.
local FIELDS = { "status", "head_sha", "target_sha", "ahead", "details", "from_ver", "to_ver" }

-- name -> { <FIELDS> }
M.results = {}
-- Whether a full check has ever populated the cache (vs. never run).
M.checked = false

-- Snapshot the check-computed fields of every plugin in `plugins`.
function M.store(plugins)
  local results = {}
  for _, p in ipairs(plugins) do
    local entry = {}
    for _, f in ipairs(FIELDS) do
      entry[f] = p[f]
    end
    results[p.name] = entry
  end
  M.results = results
  M.checked = true
end

-- Copy any cached fields onto `plugins` (matched by name), in place. Returns
-- true if the cache had been populated, so callers can mark the view "checked"
-- and enable update grouping/highlighting.
function M.apply(plugins)
  if not M.checked then
    return false
  end
  for _, p in ipairs(plugins) do
    local entry = M.results[p.name]
    if entry then
      for _, f in ipairs(FIELDS) do
        p[f] = entry[f]
      end
    end
  end
  return true
end

-- Forget everything (e.g. after an apply moves HEADs and makes the snapshot
-- stale). PackStatus then falls back to an unchecked view until the next check.
function M.clear()
  M.results = {}
  M.checked = false
end

return M
