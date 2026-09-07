CREATE TABLE proxy_usage_models (
	bucket INTEGER NOT NULL,
	client TEXT NOT NULL,
	model TEXT NOT NULL,
	requests INTEGER NOT NULL,
	errors INTEGER NOT NULL,
	input_tokens INTEGER NOT NULL,
	output_tokens INTEGER NOT NULL,
	estimated_requests INTEGER NOT NULL,
	cached_input_tokens INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (bucket, client, model)
);
