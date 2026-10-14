local config = require("bruno.config")

local M = {}

M.search_pickers = {
	["fzf-lua"] = function(search_dirs, prompt)
		local fzf = require("fzf-lua")
		fzf.live_grep({
			prompt = prompt .. ": ",
			search_paths = search_dirs,
			rg_opts = "--column --line-number --no-heading --color=always --smart-case --glob=*.bru --glob=*.yml",
			actions = {
				["default"] = function(selected)
					local raw = selected[1]
					-- Remove nerd font icon and any whitespace from the beginning
					local line = raw:gsub("^[^~/]*", "")
					local file = line:match("^([^:]+)")
					local expanded_path = vim.fs.normalize(vim.fn.expand(file))
					vim.cmd("edit " .. vim.fn.fnameescape(expanded_path))
				end,
			},
		})
	end,

	["snacks"] = function(search_dirs, prompt)
		local snacks = require("snacks")
		snacks.picker.grep({
			prompt = prompt .. ": ",
			glob = "{*.bru,*.yml}",
			dirs = search_dirs,
			on_select = function(item)
				vim.cmd("edit " .. item.file)
			end,
		})
	end,

	["telescope"] = function(search_dirs, prompt)
		local telescope = require("telescope.builtin")
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		telescope.live_grep({
			prompt_title = prompt,
			search_dirs = search_dirs,
			glob_pattern = "{*.bru,*.yml}",
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					vim.cmd("edit " .. selection.filename)
				end)
				return true
			end,
		})
	end,
}

M.env_pickers = {
	["fzf-lua"] = function(env_names, prompt)
		local fzf = require("fzf-lua")
		fzf.fzf_exec(env_names, {
			prompt = prompt .. ": ",
			actions = {
				["default"] = function(selected)
					if selected and selected[1] then
						config.current_env = selected[1]
						print("Bruno environment set to: " .. config.current_env)
					end
				end,
			},
		})
	end,

	["snacks"] = function(env_names, prompt)
		local snacks = require("snacks")

		snacks.picker.select(env_names, {
			prompt = prompt .. ": ",
		}, function(selected_item, idx)
			if selected_item then
				config.current_env = selected_item
				print("Bruno environment set to: " .. config.current_env)
			end
		end)
	end,

	["telescope"] = function(env_names, prompt)
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		pickers
			.new({}, {
				prompt_title = prompt,
				finder = finders.new_table({ results = env_names }),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						config.current_env = selection[1]
						print("Bruno environment set to: " .. config.current_env)
					end)
					return true
				end,
			})
			:find()
	end,
}

return M
