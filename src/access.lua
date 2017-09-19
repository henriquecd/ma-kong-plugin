local _M = {}

local req_get_headers = ngx.req.get_headers
local pargs = ngx.req.get_post_args
local req_get_headers = ngx.req.get_headers
local body = ngx.req.read_body
local string_find = string.find
local pl_stringx = require "pl.stringx"
local responses = require "kong.tools.responses"
local socket = require "socket" 
local ltn12 = require "ltn12"


local handshake = require "kong.plugins.mutualauthentication.handshake"
local util = require "kong.plugins.mutualauthentication.util"

local CONTENT_TYPE = "content-type"

local function get_content_type(content_type)
  if content_type == nil then
    return
  end
  if string_find(content_type:lower(), "application/json", nil, true) then
    return "json"
  end
end

function _M.run(conf)

    util.printToFile(debug.getinfo(1).currentline,'Inicio de access.run()')

    local content_type_value = req_get_headers()[CONTENT_TYPE]
    local content_type = get_content_type(content_type_value)
    --client library will send content_type = application/x-www-form-urlencoded
    util.printToFile(debug.getinfo(1).currentline, content_type_value)
--    if content_type == nil or content_type ~= "x-www-form-urlencoded" then
--        return
--    end  

    -- Obtem o prefixo usado no endereço (apenas para log)
    local request_uri = ngx.var.request_uri
--    if pl_stringx.endswith(request_uri, "/") then
--        request_uri = request_uri:sub(1, request_uri:len() - 1)
--    end
    util.printToFile(debug.getinfo(1).currentline,'Received uri: ' .. request_uri)
        
    -- Decide if request is:
    -- --registerComponent
    -- --unregisterComponent
    -- --requestAS
    -- --requestAP
    -- --API request
    
    if(string.match(request_uri, "unregisterComponent")) then
        handshake.unregisterComponent(conf)

    elseif(string.match(request_uri, "registerComponent")) then
        handshake.registerComponent(conf)
    
    elseif(string.match(request_uri, "requestAS")) then
        handshake.requestAS(conf)

    elseif(string.match(request_uri, "requestAP")) then
        handshake.requestAP(conf)
    end

end

return _M
