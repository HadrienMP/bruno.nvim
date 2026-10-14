local M = {
	current_env = nil,
	last_raw_output = nil,
	show_formatted_output = true,
	suppress_formatting_errors = false,
	picker = "telescope",
	collection_paths = {},
	secrets_file = "secrets.env",
}

return M
