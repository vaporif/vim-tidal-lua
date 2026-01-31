local M = {}
local terminal = require("tidal.terminal")

function M.hush()
	terminal.send("hush\n")
end

function M.silence(n)
	n = tonumber(n)
	if n and n >= 1 and n <= 16 then
		terminal.send("d" .. n .. " $ silence\n")
	else
		vim.notify("Invalid stream number: " .. tostring(n), vim.log.levels.ERROR)
	end
end

function M.play(n)
	n = tonumber(n)
	if not n or n < 1 or n > 16 then
		vim.notify("Invalid stream number: " .. tostring(n), vim.log.levels.ERROR)
		return
	end

	local pattern = "d" .. n .. "%s*%$"
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for i, line in ipairs(lines) do
		if line:match(pattern) then
			vim.api.nvim_win_set_cursor(0, { i, 0 })

			local send = require("tidal.send")
			send.send_paragraph()
			return
		end
	end

	vim.notify("Pattern d" .. n .. " not found", vim.log.levels.WARN)
end

function M.generate_completions(path)
	path = path or vim.fn.expand("~/.local/share/SuperCollider/downloaded-quarks/Dirt-Samples")

	if vim.fn.isdirectory(path) == 0 then
		vim.notify("Directory not found: " .. path, vim.log.levels.ERROR)
		return
	end

	local samples = {}
	local handle = vim.uv.fs_scandir(path)
	if handle then
		while true do
			local name, type = vim.uv.fs_scandir_next(handle)
			if not name then
				break
			end
			if type == "directory" and not name:match("^%.") then
				table.insert(samples, name)
			end
		end
	end

	table.sort(samples)

	local output_path = vim.fn.stdpath("data") .. "/tidal-samples.txt"
	local file = io.open(output_path, "w")
	if file then
		for _, sample in ipairs(samples) do
			file:write(sample .. "\n")
		end
		file:close()
		vim.notify("Generated " .. #samples .. " sample names to " .. output_path, vim.log.levels.INFO)
	else
		vim.notify("Could not write to " .. output_path, vim.log.levels.ERROR)
	end
end

return M
