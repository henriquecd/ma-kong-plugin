local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.mutualauthentication.access"
local body_filter = require "kong.plugins.mutualauthentication.body_filter"

local AuthPlugin = BasePlugin:extend()

function AuthPlugin:new()
	AuthPlugin.super.new(self, "mutualauthentication")
end

function AuthPlugin:access(conf)
	AuthPlugin.super.access(self)
	access.run(conf)
	ngx.ctx.buffer = ""
end

function AuthPlugin:body_filter(conf)
	AuthPlugin.super.body_filter(self)
    body_filter.run(conf)
end

function AuthPlugin:header_filter(conf)
    AuthPlugin.super.header_filter(self)
    -- Removing because content length will change
    request_uri = ngx.var.request_uri
    if(string.match(request_uri, "registerComponent")) then
        ngx.header["content-length"] = nil
    end
end

return AuthPlugin
