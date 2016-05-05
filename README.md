Доброго всем

# postgres-luasphinx

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

# NAME

Запросы к [Sphinx:Open Source Search Engine](http://sphinxsearch.com/) через функцию PostgreSQL на языке pllua

# SYNTAX

```sql 
select * from pllua.sphinx("select ...");
```

```sql 
select id, weight, attr[1]::int from pllua.sphinx("select ...");
```

Примеры запросов к сфинксу:

* ``` select * from <index> ... ```
* ``` select *, weight() from <index> ... ```
* ``` select *, weight() as weight from <index> ... ```
* ``` select *, weight() as w from <index> ... ```
* ``` select id from <index> ...```
* ``` select id, attr1 from <index> ...```





# INSTALL

Нужно установить pllua и luasql-mysql. На момент апрель-май 2016 я устанавливал все из исходников и репозиториев.

## PostgreSQL

Проверено на версии 9.4.7. В компиляцию ничего дополнительного не нужно включать.

## Установка Pllua

Скачал из [репы](https://github.com/pllua/pllua). Кроме того есть другая репа.

У меня постгрес установлен в домашней папке и запускаю его своим пользователем

```bash
# where pg_config is located нужно только на момент компиляции pllua
$ export PG_CONFIG="$HOME/postgres/bin/pg_config" 
```

Далее нужен сам Lua, я выбрал luajit из пакета openresty

Редактирую Makefile:

```bash
...
LUA_INCDIR = $HOME/openresty/luajit/include/luajit-2.1
LUALIB = -L$HOME/openresty/luajit/lib -lluajit-5.1
...
```
```bash
$ make && make install
```

Выяснилась какая-то ошибка с линковкой библиотек, костыль:
(или отредактировать эту переменную)
```bash
$ echo 'export LD_LIBRARY_PATH="$HOME/postgres/lib:$HOME/openresty/luajit/lib:/usr/local/lib:$LD_LIBRARY_PATH' >>  ~/.bashrc
```

Активируем pllua как расширение в нужной базе:

```bash
$ psql -с "create extension pllua;" -d <dbname>
```


## Установка luasql-mysql

Удобнее воспользоваться luarocks:

```bash
$ wget http://luarocks.org/releases/luarocks-x.y.z.tar.gz
$ tar zxpf luarocks-x.y.z.tar.gz
$ cd luarocks-x.y.z
$ CFLAGS="-O2 -march=x86-64 -pipe" ./configure --prefix=$HOME/luarocks --lua-suffix=jit --with-lua=$HOME/openresty/luajit --with-lua-include=$HOME/openresty/luajit/include/luajit-2.1
$ sudo make bootstrap
$ ~/luarocks/bin/luarocks install luasql-mysql
```

Подключить установленные пакеты рокса через окружение:

```bash
$ ~/luarocks/bin/luarocks path
$ eval $(~/luarocks/bin/luarocks path)
$ echo "eval $(~/luarocks/bin/luarocks path)" >> ~/.bashrc
```

Если я запускаю сервер постгреса через своего пользователя, то пути роксов будут видны luajit в функциях pllua. Перед запуском можно глянуть:

```bash
$ env | grep LUA
```

Проверить пути поиска LUA можно:

```bash
$ psql -c 'do $lua$ local m = require("foo") $lua$ language plluau;' -d <dbname>
```

## SQL инициализация

Все объекты помещаются в схему **pllua**

```bash
$ psql -f sphinx.lua.sql -d <dbname>
```

В таблице pllua.sphinx_config отредактировать подключение к сфинксу и может путь к модулю luasql-mysql если не применялись переменные окружения.


# SEE ALSO

https://github.com/andy128k/pg-sphinx

http://pgxn.org/search?q=fdw+mysql&in=extensions

# USEFULL

http://hyperpolyglot.org/

http://ilovelua.narod.ru/about_lua.html