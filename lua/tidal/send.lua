local M = {}
local terminal = require 'tidal.terminal'
local flash = require 'tidal.flash'
local diagnostic = require 'tidal.diagnostic'

local function is_multiline(text)
  return text:find '\n' ~= nil
end

local function tabs_to_spaces(text)
  return text:gsub('\t', '    ')
end

local function trim_trailing_whitespace(text)
  return text:gsub('%s+$', '')
end

function M.escape_text(text)
  text = tabs_to_spaces(text)
  text = trim_trailing_whitespace(text)

  if is_multiline(text) then
    text = ':{\n' .. text .. '\n:}\n'
  else
    text = text .. '\n'
  end

  return text
end

function M.send(text)
  local escaped = M.escape_text(text)
  terminal.send(escaped)
end

function M.send_line(count)
  count = count or 1
  local line = vim.api.nvim_get_current_line()
  local start_line = vim.fn.line '.'
  local end_line = start_line
  local multiline = false

  if count > 1 then
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line - 1 + count, false)
    line = table.concat(lines, '\n')
    end_line = start_line + count - 1
    multiline = true
  end

  diagnostic.record_send(vim.api.nvim_get_current_buf(), start_line, end_line, multiline)
  flash.flash_range(start_line, end_line)
  M.send(line)
end

function M.send_paragraph()
  local start_line = vim.fn.line '.'
  local end_line = start_line

  while start_line > 1 do
    local prev_line = vim.fn.getline(start_line - 1)
    if prev_line:match '^%s*$' then
      break
    end
    start_line = start_line - 1
  end

  local total_lines = vim.fn.line '$'
  while end_line < total_lines do
    local next_line = vim.fn.getline(end_line + 1)
    if next_line:match '^%s*$' then
      break
    end
    end_line = end_line + 1
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local text = table.concat(lines, '\n')
  local multiline = #lines > 1

  diagnostic.record_send(vim.api.nvim_get_current_buf(), start_line, end_line, multiline)
  flash.flash_range(start_line, end_line)
  M.send(text)
end

function M.send_visual()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local mode = vim.fn.visualmode()
  if mode == 'v' then
    local start_col = start_pos[3]
    local end_col = end_pos[3]
    if #lines == 1 then
      lines[1] = lines[1]:sub(start_col, end_col)
    else
      lines[1] = lines[1]:sub(start_col)
      lines[#lines] = lines[#lines]:sub(1, end_col)
    end
  end

  local text = table.concat(lines, '\n')
  local multiline = #lines > 1

  diagnostic.record_send(vim.api.nvim_get_current_buf(), start_line, end_line, multiline)
  flash.flash_range(start_line, end_line)
  M.send(text)
end

function M.send_range(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local text = table.concat(lines, '\n')
  local multiline = #lines > 1

  diagnostic.record_send(vim.api.nvim_get_current_buf(), start_line, end_line, multiline)
  flash.flash_range(start_line, end_line)
  M.send(text)
end

return M
