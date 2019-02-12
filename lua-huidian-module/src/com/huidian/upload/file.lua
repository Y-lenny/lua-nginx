local upload = require "resty.upload"
local cjson = require "cjson"
local result = require "common.result"
local uuid = require 'resty.uuid'
local configCache = ngx.shared.configCache;

local _M = {}

-- 文件上传
function _M.file()
    local args = ngx.req.get_uri_args()
    local realFileName = uuid:generate()

    local chunk_size = 4096
    local form, err = upload:new(chunk_size)
    if not form then
        ngx.log(ngx.ERR, "failed to new upload: ", err)
        ngx.say(cjson.encode(result:error('failed to new upload')))
        return
    end

    form:set_timeout(1000)

    -- 字符串 split 分割
    string.split = function(s, p)
        local rt= {}
        string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
        return rt
    end

    -- 支持字符串前后 trim
    string.trim = function(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end

    -- 保存根路径
    local saveRootPath = configCache:get('projectPath') .. "/images/"
    -- 文件对象
    local fileToSave
    -- 是否成功保存
    local ret_save = false

    while true do
        local typ, res, err = form:read()
        if not typ then
            ngx.say("failed to read: ", err)
            return
        end

        if typ == "header" then
            -- 读取header
            local key = res[1]
            local value = res[2]
            if key == "Content-Disposition" then
                -- 解析上传的文件名
                -- form-data; name="testFileName"; filename="testfile.txt"
                local kvlist = string.split(value, ';')
                for _, kv in ipairs(kvlist) do
                    local seg = string.trim(kv)
                    if seg:find("filename") then
                        local kvfile = string.split(seg, "=")
                        local filename = string.sub(kvfile[2], 2, -2)
                        if filename then
                            realFileName = realFileName .. '.' .. filename:match(".+%.(%w+)$")
                            fileToSave = io.open(saveRootPath .. realFileName, "w+")
                            if not fileToSave then
                                ngx.say("failed to open file ", filename)
                                return
                            end
                            break
                        end
                    end
                end
            end
        elseif typ == "body" then
            -- 读取 body
            if fileToSave then
                fileToSave:write(res)
            end
        elseif typ == "part_end" then
            -- 写结束 关闭文件
            if fileToSave then
                fileToSave:close()
                fileToSave = nil
            end
            
            ret_save = true
        elseif typ == "eof" then
            -- 读取结束
            break
        else
            -- do things
        end
    end

    ngx.say(cjson.encode(result:success("save file ok")))
end

return _M