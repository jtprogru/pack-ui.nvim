local cache = require("pack_ui.cache")

describe("cache", function()
  before_each(function()
    cache.clear()
  end)

  it("apply is a no-op until a check has been stored", function()
    local plugins = { { name = "foo", status = "idle" } }
    assert.is_false(cache.apply(plugins))
    assert.equals("idle", plugins[1].status)
  end)

  it("stores and re-applies the check-computed fields by name", function()
    cache.store({
      { name = "foo", status = "update", ahead = 3, from_ver = "aaaaaaa", to_ver = "bbbbbbb" },
      { name = "bar", status = "uptodate", ahead = 0 },
    })

    -- A fresh collect() shape: only name/idle known, the rest to be filled in.
    local plugins = {
      { name = "bar", status = "idle" },
      { name = "foo", status = "idle" },
    }
    assert.is_true(cache.apply(plugins))
    assert.equals("update", plugins[2].status)
    assert.equals(3, plugins[2].ahead)
    assert.equals("aaaaaaa", plugins[2].from_ver)
    assert.equals("bbbbbbb", plugins[2].to_ver)
    assert.equals("uptodate", plugins[1].status)
  end)

  it("leaves plugins absent from the last check untouched", function()
    cache.store({ { name = "foo", status = "update", ahead = 1 } })
    local plugins = { { name = "newcomer", status = "idle" } }
    assert.is_true(cache.apply(plugins))
    assert.equals("idle", plugins[1].status)
    assert.is_nil(plugins[1].ahead)
  end)

  it("clear forgets the snapshot", function()
    cache.store({ { name = "foo", status = "update" } })
    cache.clear()
    local plugins = { { name = "foo", status = "idle" } }
    assert.is_false(cache.apply(plugins))
    assert.equals("idle", plugins[1].status)
  end)

  it("a later store replaces the previous snapshot", function()
    cache.store({ { name = "foo", status = "update", ahead = 2 } })
    cache.store({ { name = "foo", status = "uptodate", ahead = 0 } })
    local plugins = { { name = "foo", status = "idle" } }
    cache.apply(plugins)
    assert.equals("uptodate", plugins[1].status)
    assert.equals(0, plugins[1].ahead)
  end)
end)
