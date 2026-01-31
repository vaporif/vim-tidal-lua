local M = {}

local config = require("tidal.config")
local send = require("tidal.send")
local commands = require("tidal.commands")
local terminal = require("tidal.terminal")

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

return M
