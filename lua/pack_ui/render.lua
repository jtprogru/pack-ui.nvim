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

-- Custom groups so update rows can be emphasised (bold) independently of the
-- status-glyph colour, and the column/section headers read as chrome. Defined
-- with names of our own so a user's colorscheme never clobbers them; `default`
-- lets a user override any of them via their own nvim_set_hl if they wish.
api.nvim_set_hl(0, "PackUiUpdate", { bold = true, default = true })
api.nvim_set_hl(0, "PackUiColumns", { link = "Comment", default = true })
api.nvim_set_hl(0, "PackUiSection", { link = "Title", default = true })

-- Pad `s` on the right to `w` display columns (multibyte-aware, unlike %-Ns).
local function padright(s, w)
  local gap = w - api.nvim_strwidth(s)
  return gap > 0 and (s .. (" "):rep(gap)) or s
end

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

-- The "revision / version" cell for a plugin row. Update rows read as
-- "current → latest" (Mason-style); everything else shows the current rev.
local function ref_cell(p)
  if p.status == "update" then
    local from = p.from_ver or M.short(p.head_sha ~= nil and p.head_sha or p.rev)
    local to = p.to_ver or M.short(p.target_sha)
    return ("%s → %s"):format(from, to)
  end
  return M.short(p.head_sha ~= nil and p.head_sha or p.rev)
end

-- The trailing "status / version" cell. Update rows show the commit count; the
-- rest fall back to the tracked version (branch/tag) or the status text.
local function note_cell(p, st)
  if p.status == "update" then
    return ("%d new"):format(p.ahead or 0)
  end
  local ver = M.ver_str(p)
  if ver ~= "" then
    return ver
  end
  return st.text or ""
end

-- Display order: once a check has run, updatable plugins float to the top
-- (Mason-style), each group kept in the plugins' existing alphabetical order.
local function display_order(plugins, grouped)
  local order = {}
  for i = 1, #plugins do
    order[i] = i
  end
  if grouped then
    table.sort(order, function(ia, ib)
      local a, b = plugins[ia], plugins[ib]
      local au, bu = a.status == "update", b.status == "update"
      if au ~= bu then
        return au
      end
      return ia < ib
    end)
  end
  return order
end

-- Render `state.plugins` into `state.buf` and (re)build `state.line_map`.
-- Also sets `state.first_row`: the buffer line of the first plugin row.
function M.draw(state)
  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    return
  end

  local plugins = state.plugins
  local namew = 6 -- at least as wide as the "Plugin" column header
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

  local grouped = state.checked and n_upd > 0
  local order = display_order(plugins, grouped)

  -- Width of the "revision" cell, so the trailing note column lines up across
  -- rows regardless of whether a row shows a plain sha or a "from → to" pair.
  local refw = 7
  for _, p in ipairs(plugins) do
    refw = math.max(refw, api.nvim_strwidth(ref_cell(p)))
  end

  -- Column header, aligned to the row layout. The 9-column prefix matches the
  -- " [ ] · ● " mark/status/active cluster that precedes every plugin name.
  local prefix = (" "):rep(9)
  local col_header = prefix .. padright("Plugin", namew) .. "  " .. padright("Revision", refw) .. "  Version / status"

  local lines = { head, "", col_header }
  state.line_map = {}
  state.first_row = nil
  local rows = {} -- buffer line -> { p, st } for highlighting
  local sections = {} -- buffer line -> section header (no plugin)

  local emitted_update, emitted_rest = false, false
  for _, i in ipairs(order) do
    local p = plugins[i]
    if grouped and p.status == "update" and not emitted_update then
      lines[#lines + 1] = "  ── updates available ──"
      sections[#lines] = true
      emitted_update = true
    elseif grouped and p.status ~= "update" and not emitted_rest then
      lines[#lines + 1] = "  ── up to date ──"
      sections[#lines] = true
      emitted_rest = true
    end

    local st = M.STATUS[p.status] or M.STATUS.idle
    local mark = p.selected and "[x]" or "[ ]"
    local active = p.active and "●" or "○"
    local pad = (" "):rep(namew - api.nvim_strwidth(p.name))
    local ref = padright(ref_cell(p), refw)
    local line = (" %s %s %s %s%s  %s  %s"):format(mark, st.sym, active, p.name, pad, ref, note_cell(p, st))
    lines[#lines + 1] = line
    state.line_map[#lines] = i
    state.first_row = state.first_row or #lines
    rows[#lines] = { p = p, st = st }
  end

  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  api.nvim_buf_clear_namespace(state.buf, M.ns, 0, -1)
  -- nvim_buf_add_highlight is deprecated (0.11+); use extmarks directly.
  api.nvim_buf_set_extmark(state.buf, M.ns, 0, 0, {
    end_row = 0,
    end_col = #head,
    hl_group = "Title",
  })
  api.nvim_buf_set_extmark(state.buf, M.ns, 2, 0, {
    end_line = 2,
    end_col = #col_header,
    hl_group = "PackUiColumns",
  })
  for bufline in pairs(sections) do
    local l = bufline - 1
    api.nvim_buf_set_extmark(state.buf, M.ns, l, 0, {
      end_row = l,
      end_col = #lines[bufline],
      hl_group = "PackUiSection",
    })
  end
  for bufline, meta in pairs(rows) do
    local l = bufline - 1
    -- Status glyph cluster (byte cols 0..8 cover " [ ] · ").
    api.nvim_buf_set_extmark(state.buf, M.ns, l, 0, {
      end_row = l,
      end_col = 8,
      hl_group = meta.st.hl,
    })
    -- Emphasise the whole updatable row in bold so it stands out at a glance.
    if meta.p.status == "update" then
      api.nvim_buf_set_extmark(state.buf, M.ns, l, 0, {
        end_line = l + 1,
        end_col = 0,
        hl_group = "PackUiUpdate",
        hl_eol = true,
      })
    end
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
