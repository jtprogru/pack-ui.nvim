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
end)
