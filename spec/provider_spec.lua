local provider = require 'provider'

describe('Provider', function()
  before_each(function()
    ngx.ctx.configuration = {}
  end)

  teardown(function()
    ngx.ctx.configuration = nil
  end)

  it('has access function', function()
    assert.truthy(provider.access)
    assert.same('function', type(provider.access))
  end)

  it('has authorize function', function()
    assert.truthy(provider.authorize)
    assert.same('function', type(provider.authorize))
  end)

  it('has post_action_content function', function()
    assert.truthy(provider.post_action_content)
    assert.same('function', type(provider.post_action_content))
  end)

  it('has services', function()
    assert.falsy(provider.services)
    provider.init()
    assert.truthy(provider.services)
    assert.same('table', type(provider.services))
  end)

  it('finds service by host', function()
    local example = { hosts = { 'example.com'} }
    provider.services = { example }
    assert.same(example, provider.find_service('example.com'))
    assert.falsy(provider.find_service('unknown'))
  end)
end)
