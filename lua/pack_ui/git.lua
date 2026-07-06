-- Update detection via plain git.
--
-- vim.pack exposes no API to answer "does this plugin have new commits?" without
-- opening its own tabpage buffer, so we compute it ourselves. This is
-- display-only and best-effort: the actual apply always goes through
-- vim.pack.update(names, { force = true }), which owns version resolution and
-- the lockfile. If detection here is wrong, the worst case is a misleading row.

local M = {}

-- Run git asynchronously in `cwd`. `cb(ok, stdout, stderr)` may run in a fast
-- event context, so callers must vim.schedule() before touching buffers.
local function git(args, cwd, cb)
  local cmd = { "git", "-c", "gc.auto=0" }
  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    cb(res.code == 0, res.stdout or "", res.stderr or "")
  end)
end

-- Resolve the git ref a plugin should track, mirroring vim.pack's own rules:
--   nil            -> the remote default branch (origin/HEAD)
--   "branch"       -> origin/<branch>
--   "tag"|"sha"    -> used verbatim
--   version range  -> greatest semver tag satisfying the range
local function resolve_target(p, cb)
  local v = p.version
  if v == nil then
    git({ "rev-parse", "--abbrev-ref", "origin/HEAD" }, p.path, function(ok, out)
      local ref = vim.trim(out)
      cb(ok and ref ~= "" and ref or nil)
    end)
  elseif type(v) == "string" then
    git({ "branch", "--remote", "--list", "origin/" .. v }, p.path, function(ok, out)
      if ok and vim.trim(out) ~= "" then
        cb("origin/" .. v)
      else
        cb(v)
      end
    end)
  else
    git({ "tag", "--list", "--sort=-v:refname" }, p.path, function(ok, out)
      if not ok then
        return cb(nil)
      end
      for _, tag in ipairs(vim.split(vim.trim(out), "\n", { trimempty = true })) do
        local ver = vim.version.parse(tag)
        if ver and v:has(ver) then
          return cb(tag)
        end
      end
      cb(nil)
    end)
  end
end

-- Fetch (unless offline) and compute update status for a single plugin, then
-- call `done()`. Fills p.status, p.head_sha, p.target_sha, p.ahead, p.details.
function M.check(p, offline, done)
  p.status = "checking"

  local function compare()
    resolve_target(p, function(target)
      if not target then
        p.status = "unknown"
        return done()
      end
      git({ "rev-parse", "HEAD" }, p.path, function(ok1, head)
        git({ "rev-list", "-1", target }, p.path, function(ok2, tgt)
          if not (ok1 and ok2) then
            p.status = "error"
            return done()
          end
          head, tgt = vim.trim(head), vim.trim(tgt)
          p.head_sha, p.target_sha = head, tgt
          if head == tgt then
            p.status = "uptodate"
            return done()
          end
          git({ "log", "--no-merges", "--pretty=format:%h %s", head .. ".." .. tgt }, p.path, function(ok3, log)
            p.details = ok3 and vim.split(vim.trim(log), "\n", { trimempty = true }) or {}
            p.ahead = #p.details
            p.status = "update"
            done()
          end)
        end)
      end)
    end)
  end

  if offline then
    compare()
  else
    git({ "fetch", "--quiet", "--tags", "--force", "origin" }, p.path, compare)
  end
end

return M
