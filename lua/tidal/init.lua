local M = {}

local config = require("tidal.config")
local send = require("tidal.send")
local commands = require("tidal.commands")
local terminal = require("tidal.terminal")
local diagnostic = require("tidal.diagnostic")

function M.setup(opts)
	config.setup(opts)
end

M.send = send.send
M.send_line = send.send_line
M.send_paragraph = send.send_paragraph
M.send_visual = send.send_visual
M.send_range = send.send_range

M.hush = commands.hush
M.silence = commands.silence
M.play = commands.play
M.generate_completions = commands.generate_completions

M.open_ghci = terminal.open_ghci
M.open_sc = terminal.open_sc
M.close_ghci = terminal.close_ghci
M.close_sc = terminal.close_sc

M.clear_diagnostics = diagnostic.clear

--- Statusline integration

--- Check if GHCi is running
---@return boolean
function M.is_running()
	return terminal.is_running(terminal.ghci_chan)
end

--- Check if SuperCollider is running
---@return boolean
function M.is_sc_running()
	return terminal.is_running(terminal.sc_chan)
end

--- Get current boot file path
---@return string|nil
function M.get_boot_file()
	return config.find_boot_file()
end

--- Get status table for statusline integration
---@return {running: boolean, sc_running: boolean, boot_file: string|nil}
function M.get_status()
	return {
		running = M.is_running(),
		sc_running = M.is_sc_running(),
		boot_file = M.get_boot_file(),
	}
end

--- Get formatted statusline string
---@return string
function M.statusline()
	if not M.is_running() then
		return ""
	end
	local status = "Tidal"
	if M.is_sc_running() then
		status = status .. "+SC"
	end
	return status
end

return M
