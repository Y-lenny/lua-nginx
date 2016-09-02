--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/7/11
-- Time: 20:39
-- Call send message to kafka module
--
package.path = "/data/webapps/cleancenter/spaceplus/cleantrack/lua/?.lua;;"
local product = require "nginx_track_product_message"
local key = tostring( ngx.time())
local body = ngx.req.get_body_data()
local pro = product:new({ { host = "192.168.1.204", port = 9092 } })
local ok, err = pro:send_message(key, body)
if not ok then
    ngx.say("Fail to send message : ", err)
else
    ngx.say("Success to send message")
end
