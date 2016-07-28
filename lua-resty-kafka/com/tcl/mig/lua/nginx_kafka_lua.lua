--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/7/11
-- Time: 20:39
-- To change this template use File | Settings | File Templates.
--

local cjson = require "cjson"
local client = require "resty.kafka.client"
local producer = require "resty.kafka.producer"
local broker_list = {
    { host = "192.168.160.13", port = 9092 },
    { host = "192.168.160.14", port = 9092 },
    { host = "192.168.160.15", port = 9092 };
}
local key = "key"
local headers = ngx.req.raw_header()
local body = ngx.req.get_body_data()
local message = "headers=" .. headers .. "body=" .. body
-- usually we do not use this library directly
local cli = client:new(broker_list)
local brokers, partitions = cli:fetch_metadata("test")
if not brokers then
    ngx.say("fetch_metadata failed, err:", partitions)
end
local p = producer:new(broker_list)

local offset, err = p:send("test", key, message)
if not offset then
    ngx.say("send err:", err)
    return
end
ngx.say("send success, offset: ", tonumber(offset))

-- this is async producer_type and bp will be reused in the whole nginx worker
local bp = producer:new(broker_list, { producer_type = "async" })

local ok, err = bp:send("test", key, message)
if not ok then
    ngx.say("send err:", err)
    return
end
ngx.say("send success, ok:", ok)
ngx.say("send success, ok:", message)
