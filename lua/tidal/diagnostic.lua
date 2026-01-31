local M = {}

local ns = vim.api.nvim_create_namespace("tidal_diagnostic")

-- Track the last send context for mapping errors back
M.last_send = {
	buf = nil,
	start_line = nil,
	end_line = nil,
	multiline = false,
}

--- Parse GHCi error output
---@param output string
---@return {line: number, col: number, message: string, severity: number}[]
function M.parse_errors(output)
	local errors = {}

	-- Pattern: <interactive>:LINE:COL: error: [GHC-XXXX] or warning:
	local lines = vim.split(output, "\n")
	local i = 1

	while i <= #lines do
		local line = lines[i]
		-- Match: <interactive>:41:6: error: [GHC-88464]
		local err_line, err_col = line:match("<interactive>:(%d+):(%d+):")

		if err_line then
			local severity = vim.diagnostic.severity.ERROR
			if line:match("warning") then
				severity = vim.diagnostic.severity.WARN
			end

			-- Collect message lines until next error marker or prompt
			local msg_lines = {}
			i = i + 1
			while i <= #lines do
				local next_line = lines[i]
				-- Stop at next error, prompt, or empty lines
				if next_line:match("^<interactive>:%d+:%d+:") then
					break
				end
				if next_line:match("^[%w]+>%s*$") or next_line:match("^tidal>") then
					break
				end
				-- Clean up the line
				local trimmed = next_line:gsub("^%s+", "")
				if trimmed ~= "" and not trimmed:match("^|") then
					table.insert(msg_lines, trimmed)
				end
				-- Stop after collecting enough context
				if #msg_lines >= 3 then
					break
				end
				i = i + 1
			end

			local message = table.concat(msg_lines, " ")
			if message == "" then
				message = "GHCi error"
			end

			table.insert(errors, {
				line = tonumber(err_line),
				col = tonumber(err_col),
				message = message,
				severity = severity,
			})
		else
			i = i + 1
		end
	end

	return errors
end

--- Set diagnostics on the source buffer
---@param errors {line: number, col: number, message: string, severity: number}[]
function M.set_diagnostics(errors)
	if not M.last_send.buf or not vim.api.nvim_buf_is_valid(M.last_send.buf) then
		return
	end

	local diagnostics = {}
	local base_line = M.last_send.start_line or 1

	for _, err in ipairs(errors) do
		local buf_line
		if M.last_send.multiline then
			-- For multiline (wrapped in :{ :}): line 2 = first source line
			buf_line = base_line + err.line - 2
		else
			-- For single line: GHCi reports session line number, ignore it
			-- Just put error on the line we sent
			buf_line = base_line
		end
		-- Convert to 0-indexed
		buf_line = buf_line - 1
		if buf_line < 0 then
			buf_line = 0
		end

		table.insert(diagnostics, {
			lnum = buf_line,
			col = math.max(0, err.col - 1),
			message = err.message,
			severity = err.severity,
			source = "tidal",
		})
	end

	vim.diagnostic.set(ns, M.last_send.buf, diagnostics)
end

--- Clear diagnostics from buffer
---@param buf? number Buffer handle, defaults to current
function M.clear(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	vim.diagnostic.reset(ns, buf)
end

--- Process GHCi output and update diagnostics
---@param output string
function M.process_output(output)
	if not M.last_send.buf or not vim.api.nvim_buf_is_valid(M.last_send.buf) then
		return
	end

	-- Always clear previous diagnostics first
	M.clear(M.last_send.buf)

	-- Check for errors in new output
	if not output:match("<interactive>:%d+:%d+:") then
		return
	end

	local errors = M.parse_errors(output)
	if #errors > 0 then
		M.set_diagnostics(errors)
	end
end

--- Record send context for error mapping
---@param buf number
---@param start_line number
---@param end_line number
---@param multiline boolean
function M.record_send(buf, start_line, end_line, multiline)
	M.last_send.buf = buf
	M.last_send.start_line = start_line
	M.last_send.end_line = end_line
	M.last_send.multiline = multiline or false
end

return M
