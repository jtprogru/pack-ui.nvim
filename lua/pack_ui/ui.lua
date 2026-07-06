-- Window lifecycle, keymaps, and the mark/update actions. Owns the single
-- module-level `state`; rendering is delegated to pack_ui.render and update
-- detection to pack_ui.git.

local api = vim.api
local git = require("pack_ui.git")
local render = require("pack_ui.render")
local config = require("pack_ui.config")

local M = {}

local state = {
  win = nil,
  buf = nil,
  plugins = {},
  pending = 0,
  checked = false,
  line_map = {}, -- buffer line (1-based) -> index in state.plugins
}

local function collect()
  local list = {}
  for _, pd in ipairs(vim.pack.get(nil, { info = false })) do
    list[#list + 1] = {
      name = pd.spec.name,
      src = pd.spec.src,
      version = pd.spec.version,
      active = pd.active,
      path = pd.path,
      rev = pd.rev,
      status = "idle",
      selected = false,
      details = {},
    }
  end
  table.sort(list, function(a, b)
    return a.name < b.name
  end)
  return list
end

-- ── update checking ─────────────────────────────────────────────────────────

local function run_check(offline, on_done)
  state.checked = false
  state.pending = #state.plugins
  render.draw(state)
  if state.pending == 0 then
    state.checked = true
    render.draw(state)
    if on_done then
      on_done()
    end
    return
  end
  for _, p in ipairs(state.plugins) do
    git.check(p, offline, function()
      vim.schedule(function()
        state.pending = state.pending - 1
        if state.pending == 0 then
          state.checked = true
        end
        render.draw(state)
        if state.pending == 0 and on_done then
          on_done()
        end
      end)
    end)
  end
end

-- ── actions ─────────────────────────────────────────────────────────────────

local function current_plugin()
  if not (state.win and api.nvim_win_is_valid(state.win)) then
    return nil
  end
  local row = api.nvim_win_get_cursor(state.win)[1]
  local idx = state.line_map[row]
  return idx and state.plugins[idx] or nil
end

-- Apply updates for `names` via vim.pack, then re-check offline to refresh revs.
local function apply(names)
  if #names == 0 then
    vim.notify("vim.pack: nothing to update", vim.log.levels.WARN)
    return
  end
  vim.schedule(function()
    local ok, err = pcall(vim.pack.update, names, { force = true })
    if not ok then
      vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
    end
    for _, p in ipairs(state.plugins) do
      p.selected = false
    end
    -- Revs changed on disk; recompute from already-fetched refs (offline).
    state.plugins = collect()
    run_check(true)
    vim.notify(
      ("vim.pack: updated %d plugin%s — :restart to load new code"):format(#names, #names == 1 and "" or "s"),
      vim.log.levels.INFO
    )
  end)
end

-- Update whatever is marked; fall back to the plugin under the cursor. Marking
-- an already up-to-date plugin is allowed — vim.pack just re-checks it and
-- no-ops if nothing changed.
local function update_marked()
  local names = {}
  for _, p in ipairs(state.plugins) do
    if p.selected then
      names[#names + 1] = p.name
    end
  end
  if #names == 0 then
    local p = current_plugin()
    if p then
      names[1] = p.name
    end
  end
  apply(names)
end

local function update_all()
  local names = {}
  for _, p in ipairs(state.plugins) do
    if p.status == "update" then
      names[#names + 1] = p.name
    end
  end
  -- Nothing detected yet (e.g. status view before a check): update everything.
  if #names == 0 then
    for _, p in ipairs(state.plugins) do
      names[#names + 1] = p.name
    end
  end
  apply(names)
end

local function toggle_mark()
  local p = current_plugin()
  if p then
    p.selected = not p.selected
    render.draw(state)
  end
end

local function mark_all()
  local any_unmarked = false
  for _, p in ipairs(state.plugins) do
    if not p.selected then
      any_unmarked = true
      break
    end
  end
  for _, p in ipairs(state.plugins) do
    p.selected = any_unmarked
  end
  render.draw(state)
end

local function show_changelog()
  local p = current_plugin()
  if not p then
    return
  end
  local lines
  if p.status == "update" and #p.details > 0 then
    lines = { ("%s: %d new commit%s"):format(p.name, p.ahead, p.ahead == 1 and "" or "s"), "" }
    vim.list_extend(lines, p.details)
  elseif p.status == "update" then
    lines = { ("%s has updates."):format(p.name) }
  else
    lines = {
      p.name,
      "",
      "Source:   " .. p.src,
      "Path:     " .. p.path,
      "Revision: " .. render.short(p.head_sha ~= nil and p.head_sha or p.rev),
      "Version:  " .. (render.ver_str(p) == "" and "(default branch)" or render.ver_str(p)),
      "Status:   " .. (render.STATUS[p.status] and (render.STATUS[p.status].text or p.status) or p.status),
    }
  end

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, api.nvim_strwidth(l))
  end
  width = math.min(width + 2, math.floor(vim.o.columns * 0.8))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
  local avail_rows = vim.o.lines - vim.o.cmdheight
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((avail_rows - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    style = "minimal",
    border = config.options.border,
    title = " changelog ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  for _, key in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", key, function()
      pcall(api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true, silent = true, desc = "pack-ui: close changelog" })
  end
end

local function close()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function set_keymaps()
  -- desc feeds which-key, so the in-window keys are documented the moment the
  -- float opens (which-key reads buffer-local maps).
  local map = function(keys, fn, desc)
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, fn, { buffer = state.buf, nowait = true, silent = true, desc = desc })
    end
  end
  map({ "q", "<Esc>" }, close, "pack-ui: close")
  map({ "<Space>", "<Tab>" }, toggle_mark, "pack-ui: toggle mark")
  map({ "a" }, mark_all, "pack-ui: mark/unmark all")
  map({ "<CR>", "u" }, update_marked, "pack-ui: update marked (or row under cursor)")
  map({ "U" }, update_all, "pack-ui: update all")
  map({ "r", "R" }, function()
    state.plugins = collect()
    run_check(false)
  end, "pack-ui: re-check remotes")
  map({ "K" }, show_changelog, "pack-ui: changelog / details")

  -- Plain vertical motion. Global j→gj / k→gk expr maps (and a global
  -- treesitter foldexpr) can defer this float's redraw and make scrolling look
  -- stuck below the visible edge; buffer-local plain motions bypass them.
  for _, key in ipairs({ "j", "<Down>" }) do
    vim.keymap.set("n", key, "j", { buffer = state.buf, nowait = true, silent = true })
  end
  for _, key in ipairs({ "k", "<Up>" }) do
    vim.keymap.set("n", key, "k", { buffer = state.buf, nowait = true, silent = true })
  end
end

-- ── entry point ─────────────────────────────────────────────────────────────

-- opts.check: fetch and compute updates on open.
-- opts.on_checked: callback fired once the initial check completes.
function M.open(opts)
  opts = opts or {}
  local o = config.options
  state.plugins = collect()
  state.checked = false
  state.pending = 0

  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_set_current_win(state.win)
  else
    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].filetype = "vimpack"
    local width = math.min(o.max_width, math.floor(vim.o.columns * o.width_ratio))
    local height = math.min(#state.plugins + 4, math.floor(vim.o.lines * o.height_ratio))
    -- Center on the editor grid, accounting for the border (2 rows/cols) and
    -- the command line, so the top and bottom margins are equal.
    local avail_rows = vim.o.lines - vim.o.cmdheight
    state.win = api.nvim_open_win(state.buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.max(0, math.floor((avail_rows - height - 2) / 2)),
      col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
      style = "minimal",
      border = o.border,
      title = o.title,
      title_pos = "center",
    })
    vim.wo[state.win].cursorline = true
    vim.wo[state.win].wrap = false
    -- Predictable line-by-line scrolling to the very bottom, no foldexpr work.
    vim.wo[state.win].scrolloff = 0
    vim.wo[state.win].foldmethod = "manual"
    -- One-cell left margin so the block cursor isn't flush against the border.
    vim.wo[state.win].foldcolumn = "1"
    -- Pin the key hints to the top of the window (survives scrolling).
    vim.wo[state.win].winbar = render.winbar()
    set_keymaps()
    api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(state.win),
      once = true,
      callback = function()
        state.win = nil
      end,
    })
  end

  render.draw(state)
  -- park cursor on the first plugin row
  pcall(api.nvim_win_set_cursor, state.win, { 3, 0 })

  if opts.check then
    run_check(false, opts.on_checked)
  end
end

-- Read-only overview; no network. Press `r` inside to check for updates.
function M.status()
  M.open({ check = false })
end

-- Open, check for updates, and wait for the user to apply them (pointwise or U).
function M.update()
  M.open({ check = true })
end

-- Open, check for updates, and apply all of them automatically.
function M.update_all()
  M.open({
    check = true,
    on_checked = function()
      local names = {}
      for _, p in ipairs(state.plugins) do
        if p.status == "update" then
          names[#names + 1] = p.name
        end
      end
      if #names > 0 then
        apply(names)
      else
        vim.notify("vim.pack: everything up to date", vim.log.levels.INFO)
      end
    end,
  })
end

return M
