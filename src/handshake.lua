local _M = {}

local json = require "json"
local uuid = require "uuid"
local http = require "socket.http"
local string_find = string.find

local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data
local req_set_body_data = ngx.req.set_body_data
local req_set_header = ngx.req.set_header

local CONTENT_LENGTH = "content-length"
local CONTENT_TYPE = "content-type"

local util = require "kong.plugins.mutualauthentication.util"

function unregisterComponent(conf)
end

function _M.registerComponent(conf)
    
    uuid.randomseed(socket.gettime()*10000)
    -- Generates application id
    local appId = uuid()
    appId = string.gsub(appId, "-", "")
    appId = string.sub(appId, -16)

    -- Generates application key
    local appKey = uuid()
    appKey = string.gsub(appKey, "-", "")

    local component_table = {}
    component_table["id"] = appId
    component_table["key"] = appKey
    
    -- Call req_read_body to read the request body first
    req_read_body()
    local body = req_get_body_data()
    local content_length = (body and #body) or 0
    
    body = util.transform_json_body(conf, body, component_table)
  
    req_set_body_data(body)
    req_set_header(CONTENT_LENGTH, #body)

    -- TODO Send key to application

end

function _M.requestAS(conf)

    -- Call req_read_body to read the request body first
    req_read_body()
    local body = req_get_body_data()
    local content_length = (body and #body) or 0
    if not body then
        return
    end
    local body_string = util.hex_dump(body)

    -- Generates sessionId
    local sessionId = uuid()
    sessionId = string.gsub(sessionId, "-", "")

    -- Generates transactionId
    local transactionId = uuid()
    transactionId = string.gsub(transactionId, "-", "")

    -- TODO Stores sessionId and transactionId

    -- Registers session
    local payload = [[ {"sessionId":"]] .. sessionId .. [[","transactionId":"]] 
        .. transactionId .. [["} ]]
    local response_body = { }
    local post_url = conf.kerberos_url -- TODO passar essa variável no request
    
	local res, code, response_headers, status = http.request
	{
	    -- TODO Passar url como variável
	    url = "http://kerberos:8080/kerberosintegration/rest/registry/registerSession",
	    method = "POST",
		headers =
		{
		["Content-Type"] = "application/json",
        ["Content-Length"] = payload:len()
		},
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body),
	}
	util.printResponse(res, code, response_headers, status, source, sink, response_body)

    -- sends requestAS
    local session_table = {}
    session_table["sessionId"] = sessionId
    session_table["transactionId"] = transactionId
    
    -- Inserts sessionId and TransformationId into original request
    session_table["request"] = body_string
    table.foreach(session_table, print)
    local session_string = json.encode(session_table)
  
    req_set_body_data(session_string)
    req_set_header(CONTENT_LENGTH, #session_string)
    ngx.req.set_header("Content-Type", "application/json")
end


function _M.requestAP(conf)    
    -- Call req_read_body to read the request body first
    req_read_body()
    local body = req_get_body_data()
    local content_length = (body and #body) or 0
    if not body then
        return
    end
    local body_string = util.hex_dump(body)
    
    local sessionId = string.sub(body_string, 1, 32)
    local transactionId = string.sub(body_string, 33, 64)
    local request = string.sub(body_string, 65)
    
    local request_table = {}
    request_table["sessionId"] = sessionId
    request_table["transactionId"] = transactionId
    request_table["request"] = request
    table.foreach(request_table, print)
    
    local request_string = json.encode(request_table)
  
    req_set_body_data(request_string)
    req_set_header(CONTENT_LENGTH, #request_string)
    ngx.req.set_header("Content-Type", "application/json")
    
end

return _M
