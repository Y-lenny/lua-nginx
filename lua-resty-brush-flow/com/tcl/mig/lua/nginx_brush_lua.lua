--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/8/25
-- Time: 19:49
-- To change this template use File | Settings | File Templates.
-- this module do api brush op


local tonumber = tonumber
local _M = { _VERSION = '0.01' }
local mt = { __index = _M }
local redis = require "resty.redis_iresty"
local red = redis:new({
    timeout = 6000,
    db_index = 19,
    host = "172.27.33.19",
    port = 6389,
    password = "tclonline"
})

-- add forbidden to redis
function _M.add_forbidden(self)
    local time = ngx.time()
    local res, err = red:get("user:" .. ngx.var.remote_addr .. ":" .. time)
    if err then
        ngx.say("Fail to get user ip", err)
        return nil, err
    end
    if type(res) == "string" then
        -- attack, 5 times request/s
        if tonumber(res) >= 5 then
            red:del("block:" .. self.ip)
            red.set("block:" .. self.ip, tonumber(time) + 5 * 60) --set block time
        end
    end
    return true
end

-- judge forbidden to redis
function _M.judge_forbidden(self)
    local time = ngx.time()
    local res, err = red.get("block:" .. ngx.var.remote_addr)
    if err then
        ngx.say("Block IP not bound", err)
        return nil, err
    elseif not res then
        return nil
    end
    if type(res) == "string" then
        if tonumber(res) > tonumber(time) then
            ngx.say("In forbidden", err)
            return true, "In forbidden"
        end
    end
    return nil
end

-- incr access frequency to redis
function _M.incr_frequency(self)
    local time = ngx.time()
    local ok, err = red.incr("user:" .. ngx.var.remote_addr .. ":" .. time)
    red.expire("user:" .. ngx.var.remote_addr .. ":" .. time, 5) -- set expire time
    if not ok then
        ngx.say("Fail to incr user", err)
        return nil,err
    end
    return ok
end

-- new brush lua class
function _M.new(self)
    return setmetatable(_M, mt)
end

return _M