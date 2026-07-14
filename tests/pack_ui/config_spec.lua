local config = require("pack_ui.config")

describe("config.setup", function()
  before_each(function()
    -- Start each test from a clean copy of the defaults.
    config.options = vim.deepcopy(config.defaults)
  end)

  it("returns the defaults when called with no opts", function()
    local opts = config.setup()
    assert.equals("rounded", opts.border)
    assert.equals(100, opts.max_width)
    assert.equals(" vim.pack ", opts.title)
  end)

  it("merges user opts over the defaults", function()
    local opts = config.setup({ border = "single", max_width = 80 })
    assert.equals("single", opts.border)
    assert.equals(80, opts.max_width)
    -- Untouched defaults survive the merge.
    assert.equals(0.9, opts.width_ratio)
  end)

  it("defaults zindex to Neovim's float default and lets users override it", function()
    assert.equals(50, config.setup().zindex)
    assert.equals(1, config.setup({ zindex = 1 }).zindex)
  end)

  it("defaults auto_check and auto_update to off", function()
    local opts = config.setup()
    assert.equals(false, opts.auto_check)
    assert.equals(false, opts.auto_update)
  end)

  it("opts into automation when asked", function()
    local opts = config.setup({ auto_check = true, auto_update = true })
    assert.equals(true, opts.auto_check)
    assert.equals(true, opts.auto_update)
  end)

  it("deep-merges nested keymap opts", function()
    local opts = config.setup({ keymaps = { status = "S" } })
    assert.equals("S", opts.keymaps.status)
    -- Sibling keymap defaults are preserved.
    assert.equals("<leader>p", opts.keymaps.prefix)
    assert.equals("U", opts.keymaps.update_all)
  end)

  it("mutates config.options in place", function()
    config.setup({ title = " packages " })
    assert.equals(" packages ", config.options.title)
  end)

  it("defaults the in-window keymaps", function()
    local opts = config.setup()
    assert.same({ "u" }, opts.keymaps.window.update_marked)
    assert.same({ "U" }, opts.keymaps.window.update_all)
    assert.same({ "<CR>", "K" }, opts.keymaps.window.changelog)
  end)

  it("replaces a window action wholesale, without index-merge leftovers", function()
    -- The default is { "<CR>", "K" }; overriding with a shorter list must not
    -- leave "K" behind (the vim.tbl_deep_extend list-merge footgun).
    local opts = config.setup({ keymaps = { window = { changelog = { "gc" } } } })
    assert.same({ "gc" }, opts.keymaps.window.changelog)
    -- Sibling window actions keep their defaults.
    assert.same({ "u" }, opts.keymaps.window.update_marked)
  end)

  it("accepts a string or false for a window action", function()
    local opts = config.setup({
      keymaps = { window = { update_marked = "gu", changelog = false } },
    })
    assert.equals("gu", opts.keymaps.window.update_marked)
    assert.equals(false, opts.keymaps.window.changelog)
  end)

  it("keeps the window keymaps when keymaps = false disables the global maps", function()
    config.setup({ keymaps = false })
    assert.equals(false, config.options.keymaps)
    -- The window stays operable: window_keymaps falls back to the defaults.
    assert.same({ "u" }, config.window_keymaps().update_marked)
  end)
end)
