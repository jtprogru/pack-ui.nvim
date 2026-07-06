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

local function short(sha)
  return sha and sha:sub(1, 7) or ""
end

-- Resolve the git ref a plugin should track, mirroring vim.pack's own rules,
-- and report back its `kind` so the caller can label the target as a version
-- (tags) or a plain revision (branches):
--   nil            -> the remote default branch (origin/HEAD)   kind "branch"
--   "branch"       -> origin/<branch>                           kind "branch"
--   "tag"|"sha"    -> used verbatim                             kind "verbatim"
--   version range  -> greatest semver tag satisfying the range  kind "tag"
-- The callback receives `(target, kind)`; `target` is nil when nothing matches.
local function resolve_target(p, cb)
  local v = p.version
  if v == nil then
    git({ "rev-parse", "--abbrev-ref", "origin/HEAD" }, p.path, function(ok, out)
      local ref = vim.trim(out)
      cb(ok and ref ~= "" and ref or nil, "branch")
    end)
  elseif type(v) == "string" then
    git({ "branch", "--remote", "--list", "origin/" .. v }, p.path, function(ok, out)
      if ok and vim.trim(out) ~= "" then
        cb("origin/" .. v, "branch")
      else
        cb(v, "verbatim")
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
          return cb(tag, "tag")
        end
      end
      cb(nil)
    end)
  end
end

-- Fetch (unless offline) and compute update status for a single plugin, then
-- call `done()`. Fills p.status, p.head_sha, p.target_sha, p.ahead, p.details,
-- and p.from_ver / p.to_ver — human-readable "current → latest" labels (a
-- semver tag when the plugin tracks versions, otherwise a short sha).
function M.check(p, offline, done)
  p.status = "checking"

  local function compare()
    resolve_target(p, function(target, kind)
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
            -- On a version tag, HEAD sits exactly on `target`; show it by name.
            p.from_ver = kind == "tag" and target or short(head)
            p.to_ver = p.from_ver
            return done()
          end
          -- Default labels are short shas; refine below for tag-tracked plugins.
          p.from_ver, p.to_ver = short(head), short(tgt)
          git({ "log", "--no-merges", "--pretty=format:%h %s", head .. ".." .. tgt }, p.path, function(ok3, log)
            p.details = ok3 and vim.split(vim.trim(log), "\n", { trimempty = true }) or {}
            p.ahead = #p.details
            p.status = "update"
            if kind == "tag" then
              p.to_ver = target
              -- The tag currently checked out, if HEAD sits exactly on one.
              git({ "describe", "--tags", "--exact-match", "HEAD" }, p.path, function(okd, cur)
                cur = vim.trim(cur)
                p.from_ver = (okd and cur ~= "") and cur or short(head)
                done()
              end)
            else
              done()
            end
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
