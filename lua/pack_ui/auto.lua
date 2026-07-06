-- Headless (no window) update checking and applying, driven by the `auto_check`
-- and `auto_update` options from setup() (see config.lua). Reuses the same
-- best-effort git detection as the UI; the actual apply goes through
-- vim.pack.update(names, { force = true }).

local git = require("pack_ui.git")

local M = {}

-- The minimal plugin shape git.check needs: it reads `path`/`version` and fills
-- `status`/`details`/`ahead`/`*_sha`. `name` is ours, for the notify/apply list.
local function collect()
  local list = {}
  for _, pd in ipairs(vim.pack.get(nil, { info = false })) do
    list[#list + 1] = {
      name = pd.spec.name,
      version = pd.spec.version,
      path = pd.path,
      status = "idle",
      details = {},
    }
  end
  return list
end

-- Check every managed plugin for updates (fetches from remotes), then call
-- `on_done(names)` with the names that have updates pending, on the main loop.
local function check_all(on_done)
  local plugins = collect()
  local pending = #plugins
  if pending == 0 then
    return on_done({})
  end
  for _, p in ipairs(plugins) do
    git.check(p, false, function()
      vim.schedule(function()
        pending = pending - 1
        if pending == 0 then
          local names = {}
          for _, q in ipairs(plugins) do
            if q.status == "update" then
              names[#names + 1] = q.name
            end
          end
          on_done(names)
        end
      end)
    end)
  end
end

-- Background check: notify if any plugin has updates, stay silent otherwise.
function M.check()
  check_all(function(names)
    if #names > 0 then
      vim.notify(
        ("vim.pack: %d update%s available (:PackUpdate) — %s"):format(
          #names,
          #names == 1 and "" or "s",
          table.concat(names, ", ")
        ),
        vim.log.levels.INFO
      )
    end
  end)
end

-- Background update: check, then apply every available update automatically.
function M.update()
  check_all(function(names)
    if #names == 0 then
      return
    end
    local ok, err = pcall(vim.pack.update, names, { force = true })
    if not ok then
      vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    vim.notify(
      ("vim.pack: updated %d plugin%s — :restart to load new code"):format(#names, #names == 1 and "" or "s"),
      vim.log.levels.INFO
    )
  end)
end

return M
