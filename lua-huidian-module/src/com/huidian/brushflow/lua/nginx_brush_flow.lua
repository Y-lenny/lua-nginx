--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/9/1
-- Time: 20:26
-- To change this template use File | Settings | File Templates.
-- Prevent the flow brush
--

package.path = "/data/webapps/cleancenter/spaceplus/cleantrack/lua/?.lua;;"
local brush = require "nginx_brush_lua"
local flow = require "nginx_flow_lua"
local bru = brush:new()
local flo = flow:new()

-- brush
-- judge user ip forbidden
local ok, err = bru:judge_forbidden()
if ok then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
-- add ip forbidden
bru:add_forbidden()
-- increase user ip frequency
bru:incr_frequency()

-- flow
local key = "服务器IP，请求url"
-- judge req through bucket
ok, err = flo:judge_req_through_bucket(key)
if ok then
    -- delete token bucket
    ok, err = flo:decr_token_bucket(key)
    if not ok then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    -- calculate ip:url frequency
    flo:calc_frequency(key)
    -- add token to bucket
    flo:add_token_to_bucket(key)
end


