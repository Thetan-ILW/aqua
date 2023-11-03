local class = require("class")

local UsecaseViewHandler = class()

function UsecaseViewHandler:new(usecases, models, default_results, views)
	self.usecases = usecases
	self.models = models
	self.default_results = default_results
	self.views = views
end

function UsecaseViewHandler:handle_params(params, usecase_name, results)
	local usecase = self.usecases[usecase_name]
	local result_type, result = usecase:run(params, self.models)

	local code_view_headers = results[result_type] or self.default_results[result_type]
	local code, view_name, headers = unpack(code_view_headers)

	local res_body
	if view_name then
		res_body = self.views[view_name](result)
	end

	return code or 200, headers or {}, res_body or ""
end

return UsecaseViewHandler
