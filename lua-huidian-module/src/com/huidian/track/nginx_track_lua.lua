--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/9/1
-- Time: 16:15
-- To change this template use File | Settings | File Templates.
--

package.path = "/data/webapps/cleancenter/spaceplus/cleantrack/lua/?.lua;;"
local _M = { _VERSION = '0.01' }
local mt = { __index = _M }
local client = require "resty.kafka.client"
local producer = require "resty.kafka.producer"

-- send message to kafaka
function _M.send_message(self, key, message)
    local cli = client:new(self.broker_list)
    local brokers, partitions = cli:fetch_metadata("cleancenter_spaceplus_cleantrack_topic0")
    if not brokers then
        ngx.say("fetch_metadata failed, err:", partitions)
        return nil, partitions
    end
    local pro = producer:new(self.broker_list, { producer_type = "async", max_buffering = 131072, batch_size = 26214400, flush_time = 60000 })
    if message == nil or #message == 0 or key == nil or #key == 0 then
        ngx.say("Send message or key is nil : message = " .. message .. " key = " .. key)
        return nil, "Send message or key is nil"
    end
    local ok, err = pro:send("cleancenter_spaceplus_cleantrack_topic0", key, message)
    if not ok then
        ngx.say("Fail to send message :", err)
        return nil, err
    end
    return ok
end

-- new brush lua class
function _M.new(self, broker_list)
    return setmetatable({ broker_list = broker_list }, mt)
end

return _M