local config = require("bruno.config")
local collection = require("bruno.collection")
local pickers = require("bruno.pickers")

local M = {}

function M.find_environments_dir()
	local search_dir = vim.fn.expand("%:p:h")
	local root = collection.find_collection_root(search_dir)
	if not root and vim.g.last_bruno_file then
		root = collection.find_collection_root(vim.fn.fnamemodify(vim.g.last_bruno_file, ":p:h"))
	end
	if not root then
		return ""
	end
	local env_dir = root .. "/environments"
	if vim.fn.isdirectory(env_dir) == 1 then
		return env_dir
	end
	return ""
end

function M.set_env_picker()
	local env_dir = M.find_environments_dir()
	if env_dir == "" then
		print(
			"Environments directory not found. You need to run BrunoRun on a .bru/.yml file first, or have the current buffer be a Bruno file."
		)
		return
	end

	local env_files = vim.fn.glob(env_dir .. "/*.{bru,yml,json}", false, true)
	if #env_files == 0 then
		print("No environment files found in the environments directory.")
		return
	end

	local env_names = vim.tbl_map(function(file)
		return vim.fn.fnamemodify(file, ":t:r")
	end, env_files)

	local picker_fn = pickers.env_pickers[config.picker] or pickers.env_pickers["telescope"]
	picker_fn(env_names, "Bruno Environments")
end

return M
