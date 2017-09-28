local _M = {}

local find = string.find
local lower = string.lower

local json = require "json"
local util = require "kong.plugins.mutualauthentication.util"
local req_get_body_data = ngx.req.get_body_data


function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function is_json_body(content_type)
  return content_type and find(lower(content_type), "application/json", nil, true)
end

local function get_kerberos_reply(conf, buffered_data)
    local json_body = json.decode(buffered_data)
    if json_body == nil then
        return
    end
    
    -- Get "kerberosReply" value
    kerberosReply = json_body["kerberosReply"]
    hex = string.fromhex(kerberosReply)
    return hex
end

local function getSessionId()
    local body = req_get_body_data()
    local body_json = json.decode(body)
    local sessionId = body_json["sessionId"]
    local transactionId = body_json["transactionId"]
    
    encodedString = string.fromhex(sessionId)
    encodedString = encodedString .. string.fromhex(transactionId)

    return encodedString
end

function _M.run(conf)
    -- Decide if request is:
    -- --requestAS -> append sessionId, transactionId and kerberosReply
    -- --requestAP -> send kerberosReply only
    request_uri = ngx.var.request_uri
    
    if(string.match(request_uri, "requestAS") or string.match(request_uri, "requestAP")) then   
        if is_json_body(ngx.header["content-type"]) then
            local chunk, eof = ngx.arg[1], ngx.arg[2]
            if eof then
                -- Inserts sessionId and transactionId
                kerberosReply = get_kerberos_reply(conf, ngx.ctx.buffer)
                if(string.match(request_uri, "requestAS")) then  
                    local sId = getSessionId()   
                    ngx.arg[1] = sId .. kerberosReply 
                else
                    ngx.arg[1] = kerberosReply 
                end  
       
            else
                ngx.ctx.buffer = ngx.ctx.buffer .. chunk
                ngx.arg[1] = nil
            end
        end        
    end
end

return _M
