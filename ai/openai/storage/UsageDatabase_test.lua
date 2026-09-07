local UsageRepo = require("ai.openai.UsageRepo")
local UsageDatabase = require("ai.openai.storage.UsageDatabase")
local LjsqliteDatabase = require("rdb.db.LjsqliteDatabase")

local test = {}

---@param t testing.T
function test.creates_empty_database(t)
	local storage = UsageDatabase(LjsqliteDatabase())
	storage.path = ":memory:"
	storage:open()
	t:eq(storage.db:user_version(), 1)
	t:eq(#UsageRepo(storage.models):history(3600).rows, 0)
	storage:close()
end

---@param t testing.T
function test.preserves_current_history(t)
	local storage = UsageDatabase(LjsqliteDatabase())
	storage.path = ":memory:"
	storage:open()
	local repo = UsageRepo(storage.models)
	repo:record(3600, "client", 200, {model = "a"}, {usage = {
		input_tokens = 10, output_tokens = 2, input_tokens_details = {cached_tokens = 7},
	}})
	storage:migrate()
	local rows = repo:history(3600).rows
	t:eq(#rows, 1)
	t:eq(rows[1].cached_input_tokens, 7)
	t:eq(rows[1].input_tokens, 10)
	storage:close()
end

---@param t testing.T
function test.rejects_future_version(t)
	local storage = UsageDatabase(LjsqliteDatabase())
	storage.path = ":memory:"
	storage:open()
	storage.db:user_version(2)
	t:has_error(function() storage:migrate() end)
	t:eq(storage.db:user_version(), 2)
	storage:close()
end

---@param t testing.T
function test.schema_failure_rolls_back(t)
	local db = LjsqliteDatabase()
	db:open(":memory:")
	db:exec("CREATE TABLE proxy_usage_models (bucket INTEGER)")
	local storage = UsageDatabase(db)
	t:has_error(function() storage:migrate() end)
	t:eq(db:user_version(), 0)
	t:eq(#db:query("PRAGMA table_info(proxy_usage_models)"), 1)
	db:exec("BEGIN")
	db:exec("ROLLBACK")
	db:close()
end

return test
