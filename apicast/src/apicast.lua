local configuration = require('configuration')
local provider = require('provider')

local _M = {
  _VERSION = '0.1'
}

local missing_configuration = os.getenv('APICAST_MISSING_CONFIGURATION') or 'log'

local function handle_missing_configuration(err)
  if missing_configuration == 'log' then
    ngx.log(ngx.ERR, 'failed to load configuration, continuing: ', err)
  elseif missing_configuration == 'exit' then
    ngx.log(ngx.EMERG, 'failed to load configuration, exiting: ', err)
    os.exit(1)
  else
    ngx.log(ngx.ERR, 'unknown value of APICAST_MISSING_CONFIGURATION: ', missing_configuration)
    os.exit(1)
  end
end

function _M.init()
  local config, err = configuration.init()

  if config then
    provider.init(config)
  else
    handle_missing_configuration(err)
  end
end

function _M.rewrite()
  -- load configuration if not configured
  -- that is useful when lua_code_cache is off
  -- because the module is reloaded and has to be configured again
  if not provider.configured then
    local config = configuration.boot()
    provider.init(config)
  end
end

function _M.content()
  provider.post_action_content()
end

function _M.access()
  local fun = provider.call()
  return fun()
end

function _M.body_filter()
  ngx.ctx.buffered = (ngx.ctx.buffered or "") .. string.sub(ngx.arg[1], 1, 1000)

  if ngx.arg[2] then
    ngx.var.resp_body = ngx.ctx.buffered
  end
end

function _M.header_filter()
  ngx.var.resp_headers = require('cjson').encode(ngx.resp.get_headers())
end

function _M.balancer()
  local round_robin = require 'resty.balancer.round_robin'
  local name = ngx.var.proxy_host

  local balancer = round_robin.new()
  local peers = balancer:peers(ngx.ctx[name])

  local peer, err = balancer:set_peer(peers)

  if not peer then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    ngx.log(ngx.ERR, "failed to set current backend peer: ", err)
    ngx.exit(ngx.status)
  end
end

return _M
