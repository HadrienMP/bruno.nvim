local config = require("bruno.config")

local M = {}

local function is_not_nil(value)
	return value ~= nil and value ~= vim.NIL and value ~= vim.NULL
end

function M.pretty_json_str(s, indent)
	indent = indent or "  "
	local out, level, in_str, esc = {}, 0, false, false
	for i = 1, #s do
		local ch = s:sub(i, i)
		if in_str then
			out[#out + 1] = ch
			if esc then
				esc = false
			elseif ch == "\\" then
				esc = true
			elseif ch == '"' then
				in_str = false
			end
		else
			if ch == '"' then
				in_str = true
				out[#out + 1] = ch
			elseif ch == "{" or ch == "[" then
				out[#out + 1] = ch .. "\n" .. string.rep(indent, level + 1)
				level = level + 1
			elseif ch == "}" or ch == "]" then
				level = level - 1
				out[#out + 1] = "\n" .. string.rep(indent, level) .. ch
			elseif ch == "," then
				out[#out + 1] = ch .. "\n" .. string.rep(indent, level)
			elseif ch == ":" then
				out[#out + 1] = ": "
			elseif not ch:match("%s") then
				out[#out + 1] = ch
			end
		end
	end
	return table.concat(out)
end

function M.format_headers(headers)
	if headers == nil or headers == vim.NULL or headers == vim.NIL then
		return {}
	end
	local lines = {}
	for name, value in pairs(headers) do
		if value ~= nil and value ~= vim.NULL and value ~= vim.NIL then
			table.insert(lines, string.format("%s: %s", name, value))
		end
	end
	return lines
end

function M.format_bruno_output(raw_output)
	local ok, data = pcall(vim.json.decode, raw_output)
	if not ok or not data.results or #data.results == 0 then
		return vim.split(raw_output, "\n")
	end

	local formatted = {}
	local result = data.results[1]

	table.insert(formatted, "# Request")
	table.insert(formatted, "")
	table.insert(formatted, string.format("%s `%s`", result.request.method, result.request.url))
	table.insert(formatted, "")

	local req_headers = M.format_headers(result.request.headers)
	if #req_headers > 0 then
		table.insert(formatted, "## Headers")
		table.insert(formatted, "```")
		for _, line in ipairs(req_headers) do
			table.insert(formatted, line)
		end
		table.insert(formatted, "```")
		table.insert(formatted, "## End Headers")
		table.insert(formatted, "")
	end

	table.insert(formatted, "# Response")
	table.insert(formatted, "")

	if is_not_nil(result.error) then
		table.insert(formatted, string.format("**Error:** %s", result.error))
		table.insert(formatted, "")
	end

	local status_text = is_not_nil(result.response.statusText) and " " .. tostring(result.response.statusText) or ""

	table.insert(
		formatted,
		string.format("Status: **%s%s**", tostring(result.response.status or "(no status)"), status_text)
	)

	table.insert(formatted, string.format("Time: **%dms**", result.response.responseTime))
	if config.current_env then
		table.insert(formatted, string.format("Env: **%s**", config.current_env))
	end
	table.insert(formatted, "")

	local res_headers = M.format_headers(result.response.headers)
	if #res_headers > 0 then
		table.insert(formatted, "## Headers")
		table.insert(formatted, "```")
		for _, line in ipairs(res_headers) do
			table.insert(formatted, line)
		end
		table.insert(formatted, "```")
		table.insert(formatted, "## End Headers")
		table.insert(formatted, "")
	end

	if is_not_nil(result.response.data) then
		table.insert(formatted, "# Response Data")
		table.insert(formatted, "")
		table.insert(formatted, "```json")

		local data_content = result.response.data == null and "null"
			or M.pretty_json_str(vim.json.encode(result.response.data))

		for _, line in ipairs(vim.split(data_content, "\n", { trimempty = true })) do
			table.insert(formatted, line)
		end

		table.insert(formatted, "```")
	end

	return formatted
end

return M
