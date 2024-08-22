local class = require("class")

---@class icc.Message
---@operator call: icc.Message
---@field id icc.EventId
---@field ret true?
---@field n integer
---@field [integer] any
local Message = class()

---@param id icc.EventId
---@param ret true?
---@param ... any
function Message:new(id, ret, ...)
	self.id = id
	self.ret = ret
	self.n = select("#", ...)
	for i = 1, self.n do
		self[i] = select(i, ...)
	end
end

---@return any ...
function Message:unpack()
	return unpack(self, 1, self.n)
end

return Message
