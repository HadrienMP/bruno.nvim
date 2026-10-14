local config = require("bruno.config")

local M = setmetatable({}, {
	__index = config,
	__newindex = function(_, key, value)
		config[key] = value
	end,
})

function M.setup(opts)
	opts = opts or {}
	config.collection_paths = opts.collection_paths or {}

	if opts.show_formatted_output ~= nil then
		config.show_formatted_output = opts.show_formatted_output
	end

	if opts.suppress_formatting_errors ~= nil then
		config.suppress_formatting_errors = opts.suppress_formatting_errors
	end

	if opts.picker ~= nil then
		config.picker = opts.picker
	end

	vim.api.nvim_create_user_command("BrunoRun", function()
		require("bruno.runner").run_bruno()
	end, {})
	vim.api.nvim_create_user_command("BrunoEnv", function()
		require("bruno.environment").set_env_picker()
	end, {})
	vim.api.nvim_create_user_command("BrunoSearch", function()
		require("bruno.search").bruno_search()
	end, {})
	vim.api.nvim_create_user_command("BrunoToggleFormat", function()
		require("bruno.runner").toggle_output_format()
	end, {})
end

return M
