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
    assert.same({ "u" }, opts.window_keymaps.update_marked)
    assert.same({ "U" }, opts.window_keymaps.update_all)
    assert.same({ "<CR>", "K" }, opts.window_keymaps.changelog)
    -- The window keys no longer live under `keymaps`.
    assert.is_nil(opts.keymaps.window)
  end)

  it("serves the window defaults before setup() is called", function()
    assert.same({ "u" }, config.window_keymaps().update_marked)
  end)

  it("replaces a window action wholesale, without index-merge leftovers", function()
    -- The default is { "<CR>", "K" }; overriding with a shorter list must not
    -- leave "K" behind (the vim.tbl_deep_extend list-merge footgun).
    local opts = config.setup({ window_keymaps = { changelog = { "gc" } } })
    assert.same({ "gc" }, opts.window_keymaps.changelog)
    -- Sibling window actions keep their defaults.
    assert.same({ "u" }, opts.window_keymaps.update_marked)
  end)

  it("accepts a string or false for a window action", function()
    local opts = config.setup({
      window_keymaps = { update_marked = "gu", changelog = false },
    })
    assert.equals("gu", opts.window_keymaps.update_marked)
    assert.equals(false, opts.window_keymaps.changelog)
  end)

  it("keeps the window keymaps when keymaps = false disables the global maps", function()
    config.setup({ keymaps = false })
    assert.equals(false, config.options.keymaps)
    assert.same({ "u" }, config.window_keymaps().update_marked)
  end)

  it("honours window_keymaps alongside keymaps = false", function()
    config.setup({ keymaps = false, window_keymaps = { close = "gq" } })
    assert.equals(false, config.options.keymaps)
    assert.equals("gq", config.window_keymaps().close)
  end)

  describe("deprecated keymaps.window", function()
    local deprecate = vim.deprecate
    local calls

    before_each(function()
      calls = {}
      vim.deprecate = function(...)
        calls[#calls + 1] = { ... }
      end
    end)

    after_each(function()
      vim.deprecate = deprecate
    end)

    it("still applies, per action, and warns", function()
      local opts = config.setup({ keymaps = { window = { changelog = { "gc" } } } })
      assert.same({ "gc" }, opts.window_keymaps.changelog)
      assert.same({ "u" }, opts.window_keymaps.update_marked)
      assert.equals(1, #calls)
      assert.equals("keymaps.window", calls[1][1])
      assert.equals("window_keymaps", calls[1][2])
    end)

    it("is dropped from options.keymaps once migrated", function()
      local opts = config.setup({ keymaps = { status = "S", window = { close = "gq" } } })
      assert.is_nil(opts.keymaps.window)
      -- The rest of the global keymaps survive.
      assert.equals("S", opts.keymaps.status)
    end)

    it("loses to window_keymaps when both set the same action", function()
      local opts = config.setup({
        keymaps = { window = { close = "gq", refresh = "gr" } },
        window_keymaps = { close = "Q" },
      })
      assert.equals("Q", opts.window_keymaps.close)
      -- Actions only the legacy table sets still apply.
      assert.equals("gr", opts.window_keymaps.refresh)
    end)

    it("does not warn when only window_keymaps is used", function()
      config.setup({ window_keymaps = { close = "gq" } })
      assert.equals(0, #calls)
    end)
  end)
end)
