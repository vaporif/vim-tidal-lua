local M = {}
local config = require 'tidal.config'

local ns = vim.api.nvim_create_namespace 'tidal_diagnostic'

-- Track send contexts for mapping errors back (supports multiple regions)
M.send_history = {}
M.max_history = 10

--- Get diagnostic config with backwards compatibility
---@return table
local function get_diag_config()
  local opts = config.options.diagnostics
  -- Handle old boolean format
  if type(opts) == 'boolean' then
    return { enabled = opts, virtual_text = true, signs = true, underline = true }
  end
  return opts or { enabled = false }
end

--- Configure diagnostic display
function M.configure()
  local opts = get_diag_config()
  if not opts.enabled then
    return
  end

  vim.diagnostic.config({
    virtual_text = opts.virtual_text,
    signs = opts.signs,
    underline = opts.underline,
    severity_sort = opts.severity_sort,
  }, ns)
end

--- Parse GHCi error output with improved pattern matching
---@param output string
---@return {line: number, col: number, message: string, severity: number}[]
function M.parse_errors(output)
  local errors = {}
  local lines = vim.split(output, '\n')
  local i = 1

  while i <= #lines do
    local line = lines[i]

    -- Pattern 1: <interactive>:LINE:COL: error/warning
    local err_line, err_col, err_type = line:match '<interactive>:(%d+):(%d+):%s*(%w+)'

    -- Pattern 2: <interactive>:LINE:COL-COL: error/warning (range)
    if not err_line then
      err_line, err_col, err_type = line:match '<interactive>:(%d+):(%d+)%-%d+:%s*(%w+)'
    end

    -- Pattern 3: <interactive>:(LINE,COL)-(LINE,COL): error/warning
    if not err_line then
      err_line, err_col, err_type = line:match '<interactive>:%((%d+),(%d+)%)%-[^:]+:%s*(%w+)'
    end

    -- Pattern 4: Just error marker without type
    if not err_line then
      err_line, err_col = line:match '<interactive>:(%d+):(%d+):'
      if err_line then
        err_type = line:match 'warning' and 'warning' or 'error'
      end
    end

    if err_line then
      local severity = vim.diagnostic.severity.ERROR
      if err_type and err_type:lower() == 'warning' then
        severity = vim.diagnostic.severity.WARN
      end

      -- Collect message lines
      local msg_lines = {}
      local error_code = line:match '%[GHC%-(%d+)%]'

      i = i + 1
      while i <= #lines do
        local next_line = lines[i]

        -- Stop conditions
        if next_line:match '^<interactive>:%d+' then
          break
        end
        if next_line:match '^[%w]+>%s*$' or next_line:match '^tidal>' then
          break
        end
        if next_line:match '^%s*$' and #msg_lines > 0 then
          break
        end

        -- Clean up the line
        local trimmed = next_line:gsub('^%s+', '')
        -- Skip visual indicator lines (like |, ^~~~)
        if trimmed ~= '' and not trimmed:match '^|' and not trimmed:match '^%^' then
          table.insert(msg_lines, trimmed)
        end

        -- Collect enough context but not too much
        if #msg_lines >= 5 then
          break
        end
        i = i + 1
      end

      local message = table.concat(msg_lines, ' ')
      if message == '' then
        message = error_code and ('GHCi error [GHC-' .. error_code .. ']') or 'GHCi error'
      elseif error_code then
        message = '[GHC-' .. error_code .. '] ' .. message
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

--- Find the matching send context for an error
---@param err_line number
---@return table|nil
local function find_send_context(err_line)
  -- Search history from most recent
  for i = #M.send_history, 1, -1 do
    local ctx = M.send_history[i]
    if ctx.multiline then
      -- For multiline: line 2 in GHCi = first source line
      local source_line = ctx.start_line + err_line - 2
      if source_line >= ctx.start_line and source_line <= ctx.end_line then
        return ctx
      end
    else
      -- Single line sends always map to the sent line
      return ctx
    end
  end
  return M.send_history[#M.send_history]
end

--- Set diagnostics on the source buffer
---@param errors {line: number, col: number, message: string, severity: number}[]
function M.set_diagnostics(errors)
  if #M.send_history == 0 then
    return
  end

  -- Group diagnostics by buffer
  local buf_diagnostics = {}

  for _, err in ipairs(errors) do
    local ctx = find_send_context(err.line)
    if ctx and ctx.buf and vim.api.nvim_buf_is_valid(ctx.buf) then
      local buf_line
      if ctx.multiline then
        buf_line = ctx.start_line + err.line - 2
      else
        buf_line = ctx.start_line
      end

      -- Convert to 0-indexed and clamp
      buf_line = math.max(0, buf_line - 1)

      if not buf_diagnostics[ctx.buf] then
        buf_diagnostics[ctx.buf] = {}
      end

      table.insert(buf_diagnostics[ctx.buf], {
        lnum = buf_line,
        col = math.max(0, err.col - 1),
        message = err.message,
        severity = err.severity,
        source = 'tidal',
      })
    end
  end

  -- Set diagnostics per buffer
  for buf, diagnostics in pairs(buf_diagnostics) do
    vim.diagnostic.set(ns, buf, diagnostics)
  end
end

--- Clear diagnostics from buffer
---@param buf? number Buffer handle, defaults to all tidal buffers
function M.clear(buf)
  if buf then
    vim.diagnostic.reset(ns, buf)
  else
    -- Clear from all buffers in history
    local seen = {}
    for _, ctx in ipairs(M.send_history) do
      if ctx.buf and not seen[ctx.buf] and vim.api.nvim_buf_is_valid(ctx.buf) then
        vim.diagnostic.reset(ns, ctx.buf)
        seen[ctx.buf] = true
      end
    end
  end
end

--- Process GHCi output and update diagnostics
---@param output string
function M.process_output(output)
  local opts = get_diag_config()
  if not opts.enabled then
    return
  end

  if #M.send_history == 0 then
    return
  end

  -- Clear previous diagnostics
  M.clear()

  -- Check for errors in output
  if not output:match '<interactive>:%d+' then
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
  table.insert(M.send_history, {
    buf = buf,
    start_line = start_line,
    end_line = end_line,
    multiline = multiline or false,
    timestamp = vim.uv.now(),
  })

  -- Trim history
  while #M.send_history > M.max_history do
    table.remove(M.send_history, 1)
  end
end

--- Clear send history
function M.clear_history()
  M.send_history = {}
end

return M
