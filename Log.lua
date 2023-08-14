local class = require("class")

local Log = class()

function Log:write(name, ...)
	local args = {...}
	for i, v in ipairs(args) do
		args[i] = tostring(v)
	end
	local message = table.concat(args, "\t")

	if self.console then
		io.write(("[%-8s]: %s\n"):format(name:upper(), message))
	end
	if self.path then
		love.filesystem.append(self.path, ("[%-8s%s]: %s\n"):format(name:upper(), os.date(), message))
	end
end

return Log
