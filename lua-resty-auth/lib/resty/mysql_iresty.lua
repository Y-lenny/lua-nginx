--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/9/1
-- Time: 13:56
-- To change this template use File | Settings | File Templates.
--
if not ngx.config
        or not ngx.config.ngx_lua_version
        or ngx.config.ngx_lua_version < 9011
then
    error("ngx_lua 0.9.11+ required")
end


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function(narr, nrec) return {} end
end

local cjson = require "cjson"
local mysql_c = require "mysql"
local _M = { _VERSION = '0.16' }
local mt = { __index = _M }


-- connect to mysql
function _M.connect_mod(self, mysql)
    mysql:set_timeout(self.timeout)
    local ok, err, errcode, sqlstate = mysql:connect {
        host = self.host,
        port = self.port,
        db_name = self.db_name,
        user = self.user,
        password = self.password
    }
    if not ok then
        ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
        return nil, err
    end
    return ok
end

-- keepalive to mysql
function _M.keepalive_mod(self, mysql)
    -- put it into the connection pool of size 100, with 10 seconds max idle timeout
    local ok, err = mysql:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return nil, err
    end
    return ok
end

-- close to mysql
function _M.close_mod(self, mysql)
    -- just close the connection right away:
    local ok, err = mysql:close()
    if not ok then
        ngx.say("failed to close: ", err)
        return nil, err
    end
    return ok
end

-- query to mysql read only fist value
function _M.queryFirst(self, sql)
    local mysql = mysql_c:new()
    local ok, err = self:connect_mod(mysql)
    if not ok then
        return nil, err
    end
    local res, errcode, sqlstate
    res, err, errcode, sqlstate = mysql:query(sql)
    if not res then
        ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return nil, err
    end
    if (table.getn(res) > 0) then
        local first =  cjson.decode(res)
        self.keepalive_mod()
        return first
    end
    return nil, "Not found anything"
end

function _M.new(self, opts)
    opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 1000) or 1000
    local db_name = opts.db_name or "test"
    local host = opts.host or "127.0.0.1"
    local port = opts.port or 3306
    local user = opts.user or "root"
    local password = opts.password or "123456"

    return setmetatable({
        timeout = timeout,
        db_name = db_name,
        host = host,
        port = port,
        user = user,
        password = password
    }, mt)
end

return _M