local table_util = require("table_util")
local sql_util = require("rdb.sql_util")

---@class rdb.ModelRow
---@field __model rdb.Model
---@field [string] any
local ModelRow = {}

function ModelRow:select()
	local row = self.__model:select({id = self.id})[1]
	table_util.copy(row, self)
end

---@param values table
function ModelRow:update(values)
	self.__model:update(values, {id = self.id})
	table_util.copy(values, self)
	for k, v in pairs(self) do
		if v == sql_util.NULL then
			self[k] = nil
		end
	end
end

function ModelRow:delete()
	self.__model:delete({id = self.id})
end

return ModelRow
