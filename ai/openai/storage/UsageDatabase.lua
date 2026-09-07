local class = require("class")
local TableOrm = require("rdb.TableOrm")
local Models = require("rdb.Models")
local SqliteMigrator = require("rdb.db.SqliteMigrator")
local usage_model = require("ai.openai.storage.models.proxy_usage_models")
local io_util = require("io_util")

---@class openai.UsageDatabase
---@operator call: openai.UsageDatabase
local UsageDatabase = class()

UsageDatabase.path = "userdata/ai_proxy_usage.db"
local user_version = 1

---@param db rdb.SqliteDatabase
function UsageDatabase:new(db)
	self.db = db
	self.orm = TableOrm(db)
	self.models = Models({proxy_usage_models = usage_model}, self.orm)
	self.migrator = SqliteMigrator(db)
	self.migrations = {}
end

function UsageDatabase:open()
	local db = self.db
	db:open(self.path)
	local ok, err = pcall(function()
		db:exec("PRAGMA journal_mode = WAL")
		db:exec("PRAGMA synchronous = NORMAL")
		db:exec("PRAGMA busy_timeout = 10000")
		self:migrate()
	end)
	if not ok then
		db:close()
		error(err)
	end
end

function UsageDatabase:migrate()
	assert(self.db:user_version() <= user_version, "proxy usage database is newer than this code")
	local ok, err = pcall(function()
		if self.db:user_version() == 0 then
			self.db:exec("BEGIN")
			self.db:exec(io_util.read_file("aqua/ai/openai/storage/db.sql"))
			self.db:user_version(user_version)
			self.db:exec("COMMIT")
		else
			self.migrator:migrate(user_version, self.migrations)
		end
	end)
	if not ok then
		self.db:exec("ROLLBACK")
		error(err)
	end
end

function UsageDatabase:close()
	self.db:close()
end

return UsageDatabase
