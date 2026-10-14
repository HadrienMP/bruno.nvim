local config = require("bruno.config")
local collection = require("bruno.collection")
local formatting = require("bruno.formatting")

local M = {}

local function set_buffer_properties(bufnr, name)
	vim.api.nvim_buf_set_name(bufnr, name)
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
end

local function create_or_get_sidebar()
	local sidebar_name = "Bruno Output"
	local existing_bufnr = vim.fn.bufnr(sidebar_name)

	-- Check if sidebar already exists and is visible
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		local bufnr = vim.api.nvim_win_get_buf(winid)
		if vim.api.nvim_buf_get_name(bufnr):match(sidebar_name .. "$") then
			vim.api.nvim_set_current_win(winid)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
			return bufnr
		end
	end

	-- Create new sidebar
	vim.cmd("botright vsplit")
	vim.cmd("vertical resize 80")

	local bufnr
	if existing_bufnr ~= -1 then
		bufnr = existing_bufnr
		vim.api.nvim_set_current_buf(bufnr)
	else
		bufnr = vim.api.nvim_create_buf(false, true)
		set_buffer_properties(bufnr, sidebar_name)
		vim.api.nvim_set_current_buf(bufnr)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
	return bufnr
end

function M.run_bruno()
	local current_file = collection.get_current_request_file()
	if not current_file then
		return
	end

	local root_dir = collection.find_collection_root(vim.fn.fnamemodify(current_file, ":p:h"))
	if not root_dir then
		print("Bruno collection root not found. Please ensure the file is in a Bruno collection.")
		return
	end
	local temp_file = vim.fn.tempname()
	local cmd = string.format(
		"cd %s && bru run %s -o %s",
		vim.fn.shellescape(root_dir),
		vim.fn.shellescape(current_file),
		vim.fn.shellescape(temp_file)
	)

	if config.current_env then
		cmd = cmd .. " --env " .. vim.fn.shellescape(config.current_env)
	end

	local bufnr = create_or_get_sidebar()
	vim.api.nvim_buf_set_option(bufnr, "filetype", "text")
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Running Bruno request..." })
	local output_lines = {}

	local function append_output(_, data, _)
		if data then
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(output_lines, line)
				end
			end
		end
	end

	local function on_exit(_, exit_code)
		vim.schedule(function()
			if exit_code ~= 0 and exit_code ~= 1 then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Bruno run failed with the following output:" })
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, output_lines)
			else
				local output = vim.fn.system("cat " .. vim.fn.shellescape(temp_file))
				config.last_raw_output = output
				local lines

				if config.show_formatted_output then
					vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
					vim.api.nvim_buf_set_option(bufnr, "foldmethod", "marker")
					vim.api.nvim_buf_set_option(bufnr, "foldmarker", "## Headers,End Headers")
					vim.api.nvim_buf_set_option(bufnr, "foldlevel", 0)
					local ok, result = pcall(formatting.format_bruno_output, output)
					if ok then
						lines = result
					else
						lines = vim.split(output, "\n")
						if not config.suppress_formatting_errors then
							vim.notify(
								string.format(
									"Failed to format output (%s), falling back to default formatting",
									result or "unknown error"
								),
								vim.log.levels.WARN,
								{ title = "Output Formatting" }
							)
						end
					end
				else
					vim.api.nvim_buf_set_option(bufnr, "filetype", "json")
					lines = vim.split(output, "\n")
				end

				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
			end
			vim.fn.system("rm " .. vim.fn.shellescape(temp_file))
		end)
	end

	vim.fn.jobstart(cmd, {
		on_stdout = append_output,
		on_stderr = append_output,
		on_exit = on_exit,
		stdout_buffered = true,
		stderr_buffered = true,
	})
end

function M.toggle_output_format()
	config.show_formatted_output = not config.show_formatted_output
	-- Seems unnecessary
	-- print("Bruno formatted output: " .. (config.show_formatted_output and "enabled" or "disabled"))

	if config.last_raw_output then
		local bufnr = vim.fn.bufnr("Bruno Output")
		if bufnr ~= -1 then
			local lines
			if config.show_formatted_output then
				vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
				vim.api.nvim_buf_set_option(bufnr, "foldmethod", "marker")
				vim.api.nvim_buf_set_option(bufnr, "foldmarker", "## Headers,End Headers")
				vim.api.nvim_buf_set_option(bufnr, "foldlevel", 0)
				local ok, result = pcall(formatting.format_bruno_output, config.last_raw_output)
				lines = ok and result or vim.split(config.last_raw_output, "\n")
			else
				vim.api.nvim_buf_set_option(bufnr, "filetype", "json")
				lines = vim.split(config.last_raw_output, "\n")
			end
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
		end
	end
end

return M
