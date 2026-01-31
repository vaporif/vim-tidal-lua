local M = {}
local config = require("tidal.config")

M.ghci_chan = nil
M.ghci_buf = nil
M.sc_chan = nil
M.sc_buf = nil

local function buf_valid(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function chan_valid(chan)
	if not chan then
		return false
	end
	local ok = pcall(vim.api.nvim_chan_send, chan, "")
	return ok
end

function M.is_running(chan)
	return chan_valid(chan)
end

function M.open_ghci()
	if M.is_running(M.ghci_chan) then
		return M.ghci_chan
	end

	local boot_file = config.find_boot_file()
	local ghci_cmd = config.options.ghci

	local cmd
	if boot_file then
		cmd = ghci_cmd .. " -ghci-script " .. vim.fn.shellescape(boot_file)
	else
		cmd = ghci_cmd
	end

	local current_win = vim.api.nvim_get_current_win()

	vim.cmd("belowright split")
	vim.cmd("resize 15")

	M.ghci_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(M.ghci_buf)

	M.ghci_chan = vim.fn.termopen(cmd, {
		on_exit = function()
			M.ghci_chan = nil
			M.ghci_buf = nil
		end,
	})

	vim.api.nvim_set_current_win(current_win)

	return M.ghci_chan
end

function M.open_sc()
	if not config.options.sc_enable then
		return nil
	end

	if M.is_running(M.sc_chan) then
		return M.sc_chan
	end

	local boot_file = config.find_sc_boot()
	local sclang_cmd = config.options.sclang

	local cmd = sclang_cmd
	if boot_file then
		cmd = cmd .. " " .. vim.fn.shellescape(boot_file)
	end

	local current_win = vim.api.nvim_get_current_win()

	vim.cmd("belowright vsplit")

	M.sc_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(M.sc_buf)

	M.sc_chan = vim.fn.termopen(cmd, {
		on_exit = function()
			M.sc_chan = nil
			M.sc_buf = nil
		end,
	})

	vim.api.nvim_set_current_win(current_win)

	return M.sc_chan
end

function M.send(text)
	if not M.is_running(M.ghci_chan) then
		M.open_ghci()
		vim.defer_fn(function()
			if M.ghci_chan then
				vim.api.nvim_chan_send(M.ghci_chan, text)
			end
		end, 500)
		return
	end

	vim.api.nvim_chan_send(M.ghci_chan, text)
end

function M.close_ghci()
	if buf_valid(M.ghci_buf) then
		vim.api.nvim_buf_delete(M.ghci_buf, { force = true })
	end
	M.ghci_chan = nil
	M.ghci_buf = nil
end

function M.close_sc()
	if buf_valid(M.sc_buf) then
		vim.api.nvim_buf_delete(M.sc_buf, { force = true })
	end
	M.sc_chan = nil
	M.sc_buf = nil
end

-- Track buffer position before send to only check new output
M.last_line_count = 0

--- Mark current buffer position before sending
function M.mark_position()
	if buf_valid(M.ghci_buf) then
		M.last_line_count = vim.api.nvim_buf_line_count(M.ghci_buf)
	else
		M.last_line_count = 0
	end
end

--- Get output since last mark
---@return string
function M.get_new_output()
	if not buf_valid(M.ghci_buf) then
		return ""
	end
	local line_count = vim.api.nvim_buf_line_count(M.ghci_buf)
	if line_count <= M.last_line_count then
		return ""
	end
	local lines = vim.api.nvim_buf_get_lines(M.ghci_buf, M.last_line_count, line_count, false)
	return table.concat(lines, "\n")
end

return M
