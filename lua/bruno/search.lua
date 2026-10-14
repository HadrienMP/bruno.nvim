local config = require("bruno.config")
local collection = require("bruno.collection")
local pickers = require("bruno.pickers")

local M = {}

function M.bruno_search()
	local collections = collection.get_valid_collections()
	local search_dirs = vim.tbl_map(function(collection)
		return collection.path
	end, collections)

	if #search_dirs == 0 then
		local current_file = collection.get_current_request_file()
		if current_file then
			local root = collection.find_collection_root(vim.fn.fnamemodify(current_file, ":p:h"))
			if root then
				search_dirs = { root }
			end
		end
	end

	if #search_dirs == 0 then
		print("No valid Bruno collections found.")
		return
	end

	local picker_fn = pickers.search_pickers[config.picker] or pickers.search_pickers["telescope"]
	picker_fn(search_dirs, "Bruno Files")
end

return M
