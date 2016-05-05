--[[
Запускать 

~/openresty/bin/resty sphinx.lua

--]]

local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.say("failed to instantiate mysql: ", err)
    return
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = "127.0.0.1",
    port = 9306,
--~     database = "ngx_test",
--~     user = "ngx_test",
--~     password = "ngx_test",
--~     max_packet_size = 1024 * 1024
  }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

ngx.say("connected to sphinx!")

local res, err, errno, sqlstate =
    db:query("SELECT *,weight() FROM idx1 WHERE MATCH('алла') LIMIT 10")
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

local cjson = require "cjson"
ngx.say("result: ", cjson.encode(res))

-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end