-- Pure rendering: turn UI state into buffer lines + highlights. Holds no state
-- of its own beyond the highlight namespace and static display tables.

local api = vim.api

local M = {}

M.ns = api.nvim_create_namespace("pack_ui")

M.STATUS = {
  idle = { sym = "·", hl = "Comment" },
  checking = { sym = "…", hl = "Comment", text = "checking…" },
  uptodate = { sym = "✓", hl = "Comment", text = "up to date" },
  update = { sym = "↑", hl = "DiagnosticWarn" },
  error = { sym = "✗", hl = "DiagnosticError", text = "error" },
  unknown = { sym = "?", hl = "DiagnosticHint", text = "unknown" },
}

function M.short(sha)
  return sha and sha:sub(1, 7) or ""
end

function M.ver_str(p)
  local v = p.version
  if v == nil then
    return ""
  end
  return type(v) == "string" and v or tostring(v)
end

-- Key hints live in the window bar so they stay pinned to the top of the
-- window and never scroll away with the plugin list.
local HINTS = {
  { "<Space>", "mark" },
  { "a", "all" },
  { "⏎", "update" },
  { "U", "update all" },
  { "r", "refresh" },
  { "K", "log" },
  { "q", "quit" },
}

function M.winbar()
  local parts = {}
  for _, h in ipairs(HINTS) do
    parts[#parts + 1] = ("%%#Title#%s %%#Comment#%s"):format(h[1], h[2])
  end
  return "%#Comment# " .. table.concat(parts, "   ")
end

-- Render `state.plugins` into `state.buf` and (re)build `state.line_map`.
function M.draw(state)
  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    return
  end

  local plugins = state.plugins
  local namew = 4
  local n_upd, n_sel = 0, 0
  for _, p in ipairs(plugins) do
    namew = math.max(namew, api.nvim_strwidth(p.name))
    if p.status == "update" then
      n_upd = n_upd + 1
    end
    if p.selected then
      n_sel = n_sel + 1
    end
  end

  local head = ("  vim.pack — %d plugins"):format(#plugins)
  if state.pending > 0 then
    head = head .. ("   ·   checking %d…"):format(state.pending)
  elseif state.checked then
    head = head .. ("   ·   %d update%s available"):format(n_upd, n_upd == 1 and "" or "s")
    if n_sel > 0 then
      head = head .. ("   ·   %d marked"):format(n_sel)
    end
  end

  local lines = { head, "" }
  state.line_map = {}
  local rows = {} -- buffer line -> { p, st } for highlighting

  for i, p in ipairs(plugins) do
    local st = M.STATUS[p.status] or M.STATUS.idle
    local mark = p.selected and "[x]" or "[ ]"
    local active = p.active and "●" or "○"
    local rev = M.short(p.head_sha ~= nil and p.head_sha or p.rev)
    local info = p.status == "update" and ("↑ %d new"):format(p.ahead or 0) or (st.text or "")
    local pad = (" "):rep(namew - api.nvim_strwidth(p.name))
    local line = (" %s %s %s %s%s  %-9s %-16s %s"):format(mark, st.sym, active, p.name, pad, rev, M.ver_str(p), info)
    lines[#lines + 1] = line
    state.line_map[#lines] = i
    rows[#lines] = { p = p, st = st }
  end

  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  api.nvim_buf_clear_namespace(state.buf, M.ns, 0, -1)
  -- nvim_buf_add_highlight is deprecated (0.11+); use extmarks directly. Byte
  -- columns mirror the old call exactly: 0..#head for the header, 0..8 for the
  -- status glyph cluster, 1..4 for the mark box.
  api.nvim_buf_set_extmark(state.buf, M.ns, 0, 0, {
    end_row = 0,
    end_col = #head,
    hl_group = "Title",
  })
  for bufline, meta in pairs(rows) do
    local l = bufline - 1
    api.nvim_buf_set_extmark(state.buf, M.ns, l, 0, {
      end_row = l,
      end_col = 8,
      hl_group = meta.st.hl,
    })
    if meta.p.selected then
      api.nvim_buf_set_extmark(state.buf, M.ns, l, 1, {
        end_row = l,
        end_col = 4,
        hl_group = "Visual",
      })
    end
  end
end

return M
