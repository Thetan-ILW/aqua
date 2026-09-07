local UsageRepo = require("ai.openai.UsageRepo")
local UsageDatabase = require("ai.openai.storage.UsageDatabase")
local LjsqliteDatabase = require("rdb.db.LjsqliteDatabase")

local test = {}

---@param t testing.T
function test.history(t)
	local db = UsageDatabase(LjsqliteDatabase())
	db.path = ":memory:"
	db:open()
	local repo = UsageRepo(db.models)
	repo:record(3600, "client'one", 200, {}, {usage = {input_tokens = 10, output_tokens = 4}})
	repo:record(3601, "client'one", 502, nil, nil)
	repo:record(7200, "two", 200, {input = "hello"}, {content = "world"})
	local history = repo:history(7200)
	t:eq(#history.rows, 2)
	t:eq(history.rows[1].requests, 2)
	t:eq(history.rows[1].errors, 1)
	t:eq(history.rows[1].input_tokens, 10)
	t:eq(history.rows[1].output_tokens, 4)
	t:eq(history.rows[1].estimated_requests, 1)
	t:eq(history.rows[2].estimated_requests, 1)
	t:eq(history.rows[2].input_tokens > 0, true)
	t:eq(#repo:history(7200 + 168 * 3600).rows, 0)
	db:close()
end

---@param t testing.T
function test.models_and_current_prices(t)
	local db = UsageDatabase(LjsqliteDatabase())
	db.path = ":memory:"
	db:open()
	local repo = UsageRepo(db.models, {a = {input = 2, output = 8}, b = {output = 4}})
	for _, model in ipairs({"a", "a", "b", "c"}) do
		repo:record(3600, "client", 200, {model = model}, {
			usage = {input_tokens = 1000000, output_tokens = 500000},
		})
	end
	local rows = repo:history(3600).rows
	t:eq(#rows, 3)
	t:eq(rows[1].model, "a")
	t:eq(rows[1].requests, 2)
	t:eq(rows[1].cost_usd, 12)
	t:eq(rows[2].cost_usd, 2)
	t:eq(rows[3].cost_usd, 0)
	local reopened = UsageRepo(db.models, {a = {input = 1}})
	t:eq(reopened:history(3600).rows[1].cost_usd, 2)
	t:has_error(function() UsageRepo(db.models, {a = {input = -1}}) end)
	t:has_error(function() UsageRepo(db.models, {a = {output = math.huge}}) end)
	db:close()
end



---@param t testing.T
function test.cached_input_prices(t)
	local db = UsageDatabase(LjsqliteDatabase())
	db.path = ":memory:"
	db:open()
	local repo = UsageRepo(db.models, {luna = {input = 0.2, cached_input = 0.02, output = 1.2}})
	repo:record(3600, "client", 200, {model = "luna"}, {usage = {
		input_tokens = 1000, output_tokens = 500, input_tokens_details = {cached_tokens = 800},
	}})
	repo:record(3600, "client", 200, {model = "luna"}, {usage = {
		input_tokens = 1000, output_tokens = 500,
	}})
	local row = repo:history(3600).rows[1]
	t:eq(row.input_tokens, 2000)
	t:eq(row.cached_input_tokens, 800)
	t:eq(row.output_tokens, 1000)
	t:aeq(row.cost_usd, 0.001456, 1e-12)
	t:aeq(row.cache_savings_usd, 0.000144, 1e-12)
	t:aeq(row.cost_usd + row.cache_savings_usd, 0.0016, 1e-12)
	local unpriced_cache = UsageRepo(db.models, {luna = {input = 0.2, output = 1.2}})
	t:aeq(unpriced_cache:history(3600).rows[1].cost_usd, 0.00144, 1e-12)
	t:has_error(function() UsageRepo(db.models, {luna = {cached_input = -1}}) end)
	db:close()
end



---@param t testing.T
function test.client_costs_and_cache_savings(t)
	local db = UsageDatabase(LjsqliteDatabase())
	db.path = ":memory:"
	db:open()
	local repo = UsageRepo(db.models, {a = {input = 2, cached_input = 0.2, output = 8}})
	for _, client in ipairs({"alice", "bob"}) do
		repo:record(3600, client, 200, {model = "a"}, {usage = {
			input_tokens = 1000000, output_tokens = 100000,
			input_tokens_details = {cached_tokens = client == "alice" and 800000 or 200000},
		}})
	end
	local rows = repo:history(3600).rows
	t:eq(rows[1].client, "alice")
	t:aeq(rows[1].cost_usd, 1.36, 1e-12)
	t:aeq(rows[1].cache_savings_usd, 1.44, 1e-12)
	t:eq(rows[2].client, "bob")
	t:aeq(rows[2].cost_usd, 2.44, 1e-12)
	t:aeq(rows[2].cache_savings_usd, 0.36, 1e-12)
	local unpriced = UsageRepo(db.models):history(3600).rows
	t:eq(unpriced[1].cost_usd, 0)
	t:eq(unpriced[1].cache_savings_usd, 0)
	db:close()
end

return test
