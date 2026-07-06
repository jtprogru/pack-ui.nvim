local render = require("pack_ui.render")

describe("render.short", function()
  it("truncates a sha to 7 characters", function()
    assert.equals("abc1234", render.short("abc1234def5678"))
  end)

  it("returns an empty string for nil", function()
    assert.equals("", render.short(nil))
  end)
end)

describe("render.ver_str", function()
  it("returns an empty string when version is nil", function()
    assert.equals("", render.ver_str({ version = nil }))
  end)

  it("returns a string version verbatim", function()
    assert.equals("main", render.ver_str({ version = "main" }))
  end)

  it("stringifies a non-string version (e.g. a version range)", function()
    local range = setmetatable({}, {
      __tostring = function()
        return "^1.0.0"
      end,
    })
    assert.equals("^1.0.0", render.ver_str({ version = range }))
  end)
end)

describe("render.winbar", function()
  it("includes the key hints", function()
    local bar = render.winbar()
    assert.is_truthy(bar:find("mark", 1, true))
    assert.is_truthy(bar:find("update all", 1, true))
    assert.is_truthy(bar:find("quit", 1, true))
  end)
end)

describe("render.draw", function()
  local function make_state(plugins)
    return {
      buf = vim.api.nvim_create_buf(false, true),
      plugins = plugins,
      pending = 0,
      checked = true,
      line_map = {},
    }
  end

  it("renders a header, a column row, and grouped sections", function()
    local state = make_state({
      { name = "alpha", status = "uptodate", rev = "1111111aaaa", version = nil, active = true, details = {} },
      {
        name = "beta",
        status = "update",
        ahead = 2,
        head_sha = "2222222bbbb",
        target_sha = "3333333cccc",
        version = "main",
        active = false,
        details = {},
      },
    })
    render.draw(state)

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    assert.equals("  vim.pack — 2 plugins   ·   1 update available", lines[1])
    assert.equals("", lines[2])
    -- Column headers name every field.
    assert.is_truthy(lines[3]:find("Plugin", 1, true))
    assert.is_truthy(lines[3]:find("Revision", 1, true))
    -- Updatable plugins float to the top under their own section header.
    assert.is_truthy(lines[4]:find("updates available", 1, true))
    assert.is_truthy(lines[5]:find("beta", 1, true))
    assert.is_truthy(lines[5]:find("2222222 → 3333333", 1, true))
    assert.is_truthy(lines[5]:find("2 new", 1, true))
    assert.is_truthy(lines[6]:find("up to date", 1, true))
    assert.is_truthy(lines[7]:find("alpha", 1, true))

    -- line_map maps buffer lines back to plugin indices (beta=2, alpha=1).
    assert.equals(2, state.line_map[5])
    assert.equals(1, state.line_map[7])
    -- first_row points at the first plugin row.
    assert.equals(5, state.first_row)
  end)

  it("shows the marked count and a checked mark box", function()
    local state = make_state({
      {
        name = "alpha",
        status = "uptodate",
        rev = "1111111",
        version = nil,
        active = true,
        selected = true,
        details = {},
      },
    })
    render.draw(state)

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    assert.is_truthy(lines[1]:find("1 marked", 1, true))
    -- No updates -> no section headers; the single row sits right after columns.
    assert.is_truthy(lines[4]:find("[x]", 1, true))
    assert.equals(4, state.first_row)
  end)

  it("reports pending checks in the header", function()
    local state = make_state({
      { name = "alpha", status = "checking", version = nil, active = true, details = {} },
    })
    state.checked = false
    state.pending = 1
    render.draw(state)

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    assert.is_truthy(lines[1]:find("checking 1", 1, true))
  end)

  it("applies extmark highlights without error", function()
    local state = make_state({
      { name = "alpha", status = "update", ahead = 1, head_sha = "abc", version = nil, active = true, details = {} },
    })
    render.draw(state)

    local marks = vim.api.nvim_buf_get_extmarks(state.buf, render.ns, 0, -1, {})
    -- Header title + status glyph for the single row (>= 2 marks placed).
    assert.is_true(#marks >= 2)
  end)
end)
