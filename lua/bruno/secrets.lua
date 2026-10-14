local config = require("bruno.config")

local M = {}

local function unquote(value)
	local quote = value:sub(1, 1)
	if (quote == '"' or quote == "'") and #value >= 2 and value:sub(-1) == quote then
		return value:sub(2, -2)
	end
	return value
end

function M.parse(lines)
	local secrets = {}
	for _, line in ipairs(lines) do
		line = vim.trim(line)
		if line ~= "" and line:sub(1, 1) ~= "#" then
			line = line:gsub("^export%s+", "")
			local key, value = line:match("^([^=]+)=(.*)$")
			key = key and vim.trim(key)
			if key and key:match("^[%a_][%w_.%-]*$") then
				secrets[key] = unquote(vim.trim(value))
			end
		end
	end
	return secrets
end

function M.load(root_dir)
	local path = root_dir .. "/" .. config.secrets_file
	if vim.fn.filereadable(path) ~= 1 then
		return {}
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end
	return M.parse(lines)
end

function M.to_args(secrets)
	local keys = vim.tbl_keys(secrets)
	table.sort(keys)
	local args = {}
	for _, key in ipairs(keys) do
		table.insert(args, "--env-var " .. vim.fn.shellescape(key .. "=" .. secrets[key]))
	end
	return table.concat(args, " ")
end

return M
