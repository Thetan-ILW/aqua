local sqlite = require("lsqlite3")
local IDatabase = require("rdb.IDatabase")
local sql_util = require("rdb.sql_util")

-- http://lua.sqlite.org/index.cgi/doc/tip/doc/lsqlite3.wiki

---@class rdb.LsqliteDatabase: rdb.IDatabase
---@operator call: rdb.LsqliteDatabase
local LsqliteDatabase = IDatabase + {}

---@param db string
function LsqliteDatabase:open(db)
	self.c = sqlite.open(db)
end

function LsqliteDatabase:close()
	self.c:close()
end

---@param query string
function LsqliteDatabase:exec(query)
	self.c:exec(query)
end

---@param query string
---@param bind_vals table?
---@return function
function LsqliteDatabase:iter(query, bind_vals)
	local stmt = self.c:prepare(query)
	if bind_vals then
		for i, v in ipairs(bind_vals) do
			if v ~= sql_util.NULL then
				stmt:bind(i, v)
			end
		end
	end

	local get_row = stmt:nrows()
	local i = 0
	return function()
		i = i + 1
		local row = get_row()
		if row then
			return i, row
		end
	end
end

---@param query string
---@param bind_vals table?
---@return table
function LsqliteDatabase:query(query, bind_vals)
	local objects = {}
	for i, obj in self:iter(query, bind_vals) do
		objects[i] = obj
	end
	return objects
end

return LsqliteDatabase
