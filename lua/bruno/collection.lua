local Path = require("plenary.path")
local config = require("bruno.config")

local M = {}

function M.get_valid_collections()
	return vim.tbl_filter(function(collectionInfo)
		return Path:new(collectionInfo.path):exists()
	end, config.collection_paths)
end

function M.get_current_request_file()
	local current_file = vim.fn.expand("%:p")
	local ext = vim.fn.fnamemodify(current_file, ":e")
	if ext == "bru" or ext == "yml" then
		vim.g.last_bruno_file = current_file
		return current_file
	end

	local last = vim.g.last_bruno_file
	if last and vim.fn.filereadable(last) == 1 then
		return last
	end

	print("Current file is not a .bru/.yml file and no valid last Bruno file found")
	return nil
end

function M.find_collection_root(start_dir)
	local markers = { "bruno.json", "opencollection.yml", "collection.bru" }
	local dir = vim.fn.fnamemodify(start_dir, ":p")
	while true do
		for _, marker in ipairs(markers) do
			if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
				return dir
			end
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			return nil
		end
		dir = parent
	end
end

return M
