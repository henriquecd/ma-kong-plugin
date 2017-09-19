local _M = {}

local find = string.find
local lower = string.lower

local json = require "json"
local util = require "kong.plugins.mutualauthentication.util"


function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function is_json_body(content_type)
  return content_type and find(lower(content_type), "application/json", nil, true)
end

local function transform_json_body(conf, buffered_data)
    local json_body = json.decode(buffered_data)
    if json_body == nil then
        return
    end
    
    -- Get "kerberosReply" value
    kerberosReply = json_body["kerberosReply"]
    hex = string.fromhex(kerberosReply)
    util.printToFile(debug.getinfo(1).currentline,'hex = ' .. hex)
    return hex
end

function _M.run(conf)
    if is_json_body(ngx.header["content-type"]) then
        local chunk, eof = ngx.arg[1], ngx.arg[2]
        if eof then
            local body = transform_json_body(conf, ngx.ctx.buffer)
            ngx.arg[1] = body
        else
            ngx.ctx.buffer = ngx.ctx.buffer .. chunk
            ngx.arg[1] = nil
        end
    end
end

return _M
