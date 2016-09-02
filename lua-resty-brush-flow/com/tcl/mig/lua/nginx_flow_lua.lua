--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/8/25
-- Time: 19:49
-- To change this template use File | Settings | File Templates.
-- this module do api flow op

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

-- calc url:ip frequency(access/s)
function _M.calc_frequency(self, key)
    -- model 12
    local model = ngx.time() % 12
    local ok, err = red:incr(key .. model)
    red:expire(key .. model, 10 * 60) -- set expire time
    if not ok then
        ngx.say("Fail to incr user", err)
        return nil, err
    end
    return ok
end

-- judge request whether or not through token bucket ,if time arrive and  ip:url  frequency is over min value
function _M.judge_req_through_bucket(self, key)
    -- model 12
    local model = (ngx.time() - 12) % 12
    local res, err = red:get(key .. model)
    if err then
        ngx.say("Fail to get req frequency", err)
        return nil, err
    elseif not res then
        return nil
    end
    -- through bucket threshold value
    if res > 10000 then
        return true
    end
end

-- add token to bucket ;if rate * time_distance = token_count， if token_count > size ， token_count = size。
function _M.add_token_to_bucket(self, key)
    -- Get bucket count from redis,if not found ,to create it
    local res, err = red:get(key)
    if err then
        ngx.say("Fail to get bucket", err)
        return nil, err
    elseif not res then
        return true
    end
    -- model 12
    local model = (ngx.time() - 12) % 12
    local res_freq
    res_freq, err = red:get(key .. model)
    if err then
        ngx.say("Fail to get req frequency", err)
        return nil, err
    elseif not res_freq then
        ngx.say("Need not to add token bucket")
        return true
    end
    -- add ten minute token bucket
    local addTokenBucketCount = res_freq * 2
    local tokenBucketStandSize = 10000 * 10 * 60
    if addTokenBucketCount > tokenBucketStandSize then
        addTokenBucketCount = tokenBucketStandSize
    end
    local ok
    ok, err = red:set(key, addTokenBucketCount)
    red:expire(key, 5 * 60) -- set expire time
    if not ok then
        ngx.say("Fail to set token bucket", err)
        return nil, err
    end
    return ok
end

-- decrement token to bucket ,if start bucket and request access to bucket
function _M.decr_token_bucket(self, key)
    local res, err = red:decr(key)
    if not res then
        ngx.say("Fail to decri token bucket", err)
        return nil, err
    end
    if res < 0 then
        return nil
    end
    return true
end

-- new brush lua class
function _M.new(self)
    return setmetatable(_M, mt)
end

return _M