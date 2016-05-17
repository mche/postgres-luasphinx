CREATE TABLE IF NOT EXISTS pllua.sphinx_config (
  "key"         varchar NOT NULL primary key,
  "value"       varchar NOT NULL
);

--GRANT ALL ON sphinx_config TO PUBLIC;

INSERT INTO pllua.sphinx_config ("key", "value") VALUES
  ('host', '127.0.0.1'),
  ('port', '9306'),
  ('path', '~/bar/?.lua;~/foo/?.lua'),
  ('cpath', '~/openresty/lualib/?.so')
;

-- update pllua.sphinx_config set value = '~/?.lua' where key='path';


CREATE TYPE pllua.sphinx_result AS (id int, attr text[], weight int);

CREATE OR REPLACE FUNCTION pllua.sphinx(query text)
 RETURNS SETOF pllua.sphinx_result
as $code$
if _U == nil then _U = {} end
if _U.sphinx == nil then
  local conf = {}
  local row = {}
  for row in server.rows('SELECT * FROM pllua.sphinx_config') do
      conf[row['key']] = row['value']
    end
  --print(package.cpath)
  if conf.cpath and conf.cpath ~= "" then
    package.cpath = package.cpath .. ";" .. string.gsub(conf.cpath, "~", os.getenv('HOME'))
  end
  if conf.path and conf.path ~= "" then
    package.path = package.path .. ";" .. string.gsub(conf.path, "~", os.getenv('HOME'))
  end
  -- load driver
  local driver = require "luasql.mysql"
-- create environment object
  local env = assert (driver.mysql(), "Проблемы с драйвером mysql")
-- connect to data source

  _U.sphinx = {
    conf = conf,
    env = env,
    
    connected = function(self)
      return self.connection and true
    end,
    
    connect = function(self)
      local conn, err = self.env:connect("",nil,nil,self.conf.host, self.conf.port)
      self.connection = conn
      if not self.connection then
        print("Не смог соединиться к сфинксу", err)
        return nil, err
      end
      return self
    end,
    
    close = function(self)
      if self.connection:close() then
        self.connection = nil
        return self
      else 
        return nil, "can't close connection -- it's still being used."
      end
    end,
    
    reconnect = function(self)
      self.connection=nil
      return self:connect()
    end,
    -- @param str query
    -- @return cursor or [nil, err] on error
    query = function(self, str)
      local conn, res, err = self.connection, nil, nil
      res, err = conn:execute(str)
      if not res and type(err)=="string"
        and err:match("MySQL server has gone away")
        then
        if self:reconnect() then
          conn = self.connection
          print("Переподключился к сфинксу", conn)
          res, err = conn:execute(str)
        else
          print("Соединение со сфинксом окончательно потеряно.")
        end
      end
      if not res then
--        local error = err .. ". Query was: " .. str
        print("Ошибка запроса к индексу сфинкса", err)
        return nil, error
      end
      return res
    end
  }
  assert (_U.sphinx:connect(), "Не смог соединиться к сфинксу")
  print("Соединился к сфинксу", _U.sphinx.connection)
end

--local cjson = require "cjson"

-- retrieve a cursor
local cur = assert (_U.sphinx:query(query), "Ошибка запроса к индексу сфинкса")
local row = cur:fetch ({}, "a")
while row do
  --print(cjson.encode(row))
  local o = {id=row.id, attr=nil, weight=(row['weight'] or row['weight()'] or row['w'])}
  row.id, row['weight'], row['weight()'], row['w'] = nil, nil, nil, nil
  local attr = {}
  for k,v in pairs(row) do attr[#attr+1] = v end
  if #attr > 0 then o.attr = attr end
  coroutine.yield(o)
  row = cur:fetch (row, "a")-- reusing the table of results
end
cur:close() -- already closed because all the result set was consumed
$code$ language plluau;

--select * from pllua.sphinx('SELECT * FROM idx1 WHERE MATCH(''алла'') LIMIT 10;');
