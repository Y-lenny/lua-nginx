--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/8/25
-- Time: 20:00
-- To change this template use File | Settings | File Templates.
--

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
local hmac = require "resty.hmac"
local secret = "clean`1234567890-=~!@#$%^&*()_+"
local hm = hmac:new(secret)
local mysql = require "resty.mysql_iresty"
local my = mysql:new({
    timeout = 6000,
    db_name = "spaceplus",
    host = "192.168.0.1",
    port = 3307,
    user = "work@TCL",
    password = "work@TCL"
})

-- Query user by token from redis
function _M.queryUserByTokenFromRedis(self, token)
    local res, err = red.get(token)
    if not res then
        ngx.say("user not exist in redis", err)
        return nil, err
    end
    return res
end

-- Query user by token from redis
function _M.setUserByTokenFromRedis(self, token, user)
    local ok, err = red.set(token, user)
    -- Set token expire time
    red:expire(token, 30 * 60 * 60)
    if not ok then
        ngx.say("user not exist in redis", err)
        return nil, err
    end
    return ok
end

-- Query user by username and password from mysql
function _M.queryUserByUsernameAndPwdFromMysql(self, username, password)
    local username = ngx.quote_sql_str(username)
    local password = ngx.quote_sql_str(password)
    local sql_normal = [[select id, name from user where username=]] .. username .. [[ and password=]] .. password .. [[ limit 1;]]
    local res, err = my:query(sql_normal)
    if not res then
        ngx.say("user not exsit in db", err)
        return nil, err
    end
    return res
end

-- provide cookie to client
function _M.provideRequestCookie(self, delimiter)
    local date = os.date("!%a, %d %b %Y %H:%M:%S +0000")
    local request_headers = ngx.req.get_headers()
    local imei = request_headers["imei"]
    local message = { imei = imei, date = date }
    local res, err = hm:generate_headers("AWS", imei, "sha1", date, message, delimiter)
    if not res then
        ngx.say("Fail to provide request cookie", err)
        return nil, err
    end
    ngx.header.date = res.date
    ngx.header.auth = res.auth
    return true
    -- TODO
end

-- validate request cookie from header
function _M.validateRequestCookie(self, delimiter)
    local request_headers = ngx.req.get_headers()
    local imei = request_headers["imei"]
    local date = request_headers["date"]
    local message = { imei = imei, date = date }
    local ok, err = hm:check_headers("AWS", imei, "sha1", message, delimiter)
    if not ok then
        ngx.say("Fail to validate request cookie", err)
        return nil, err
    end
end

-- privde token to client
function _M.provideRequestToken(self, delimiter)
    local request_headers = ngx.req.get_headers()
    local username = request_headers["username"]
    local password = request_headers["password"]
    local imei = request_headers["imei"]
    local date = os.date("!%a, %d %b %Y %H:%M:%S +0000")
    local res, err = self:queryUserByUsernameAndPwdFromMysql(username, password)
    if not res then
        ngx.say("Fail to find user", err)
        return nil, err
    end
    local message = { username = username, password = password, imei = imei, date = date }
    res, err = hm:generate_headers("AWS", imei, "sha1", date, message, delimiter)
    if not res then
        ngx.say("Fail to provide request cookie", err)
        return nil, err
    end
    -- TODO
    --    ngx.header.date = res.date
    --    ngx.header.auth = res.auth
    -- Set user token to redis
    local ok
    ok, err = self.setUserByTokenFromRedis(res.auth, res)
    if not ok then
        ngx.say("Fail to set user token to redis", err)
        return nil, err
    end
    return true
end

-- validate request token from redis
function _M.validateRequestToken(self, token)
    local res, err = self:queryUserByTokenFromRedis(token)
    if not res then
        ngx.say("Fail to validate request token", err)
        return nil, err
    end
    return true
end

-- validate request cookie whether or not valid
function _M.validateRequestAuth(self)
    local request_headers = ngx.req.get_headers()
    local verify = request_headers["verify"]
    local status = false
    if verify then
        status = self.validateRequestToken()
    else
        status = self.validateRequestCookie()
    end
    return status
end

-- new brush lua class
function _M.new(self)
    return setmetatable(_M, mt)
end