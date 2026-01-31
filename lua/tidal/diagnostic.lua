local M = {}

local ns = vim.api.nvim_create_namespace("tidal_diagnostic")

-- Track the last send context for mapping errors back
M.last_send = {
	buf = nil,
	start_line = nil,
	end_line = nil,
}

--- Parse GHCi error output
---@param output string
---@return {line: number, col: number, message: string, severity: number}[]
function M.parse_errors(output)
	local errors = {}

	-- Pattern: <interactive>:LINE:COL: error: or <interactive>:LINE:COL: warning:
	-- GHCi errors can span multiple lines, collect until next error or end
	local lines = vim.split(output, "\n")
	local i = 1

	while i <= #lines do
		local line = lines[i]
		local err_line, err_col, err_type = line:match("<interactive>:(%d+):(%d+):%s*(%w+)")

		if err_line then
			local severity = vim.diagnostic.severity.ERROR
			if err_type == "warning" then
				severity = vim.diagnostic.severity.WARN
			end

			-- Collect message lines until next error marker or blank line sequence
			local msg_lines = {}
			i = i + 1
			while i <= #lines do
				local next_line = lines[i]
				-- Stop at next error or empty output marker
				if next_line:match("^<interactive>:%d+:%d+:") then
					break
				end
				-- Skip the initial error type line if present
				if not next_line:match("^%s*$") or #msg_lines > 0 then
					-- Trim leading whitespace for cleaner display
					local trimmed = next_line:gsub("^%s*[•]?%s*", "")
					if trimmed ~= "" then
						table.insert(msg_lines, trimmed)
					end
				end
				-- Stop after collecting reasonable message
				if #msg_lines >= 5 then
					break
				end
				i = i + 1
			end

			table.insert(errors, {
				line = tonumber(err_line),
				col = tonumber(err_col),
				message = table.concat(msg_lines, " "),
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
		-- Map interactive line back to buffer line
		local buf_line = base_line + err.line - 2 -- -1 for 0-index, -1 for :{ wrapper
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
	-- Clear previous diagnostics on successful evaluation
	if output:match("^[%s\n]*$") or not output:match("<interactive>:%d+:%d+:") then
		if M.last_send.buf and vim.api.nvim_buf_is_valid(M.last_send.buf) then
			M.clear(M.last_send.buf)
		end
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
function M.record_send(buf, start_line, end_line)
	M.last_send.buf = buf
	M.last_send.start_line = start_line
	M.last_send.end_line = end_line
end

return M
