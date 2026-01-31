local M = {}
local config = require 'tidal.config'

M.ghci_chan = nil
M.ghci_buf = nil
M.sc_chan = nil
M.sc_buf = nil

-- Output buffer for accumulating GHCi responses
M.output_buffer = {}
M.pending_check = false

-- Callback for processing output
M.on_output = nil

local function buf_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function chan_valid(chan)
  if not chan then
    return false
  end
  local ok = pcall(vim.api.nvim_chan_send, chan, '')
  return ok
end

function M.is_running(chan)
  return chan_valid(chan)
end

--- Check if output indicates GHCi is ready (prompt returned)
---@param line string
---@return boolean
local function is_prompt(line)
  -- Match common GHCi prompts: tidal>, Prelude>, *Module>, ghci>
  return line:match '^tidal>' ~= nil or line:match '^Prelude[%w%.]*>' ~= nil or line:match '^%*?[%w%.]+>' ~= nil or line:match '^ghci>' ~= nil
end

--- Process accumulated output when prompt is detected
local function flush_output()
  if #M.output_buffer == 0 then
    return
  end

  local output = table.concat(M.output_buffer, '\n')
  M.output_buffer = {}

  if M.on_output then
    vim.schedule(function()
      M.on_output(output)
    end)
  end
end

--- Handle stdout from GHCi
---@param _ any job id (unused)
---@param data string[]
local function on_stdout(_, data)
  if not data then
    return
  end

  for _, line in ipairs(data) do
    if line ~= '' then
      table.insert(M.output_buffer, line)
    end

    -- Check if this line is a prompt (GHCi is ready)
    if is_prompt(line) then
      -- Small delay to ensure all output is captured
      if not M.pending_check then
        M.pending_check = true
        vim.defer_fn(function()
          M.pending_check = false
          flush_output()
        end, 50)
      end
    end
  end
end

function M.open_ghci()
  if M.is_running(M.ghci_chan) then
    return M.ghci_chan
  end

  local boot_file = config.find_boot_file()
  local ghci_cmd = config.options.ghci

  local cmd
  if boot_file then
    cmd = ghci_cmd .. ' -ghci-script ' .. vim.fn.shellescape(boot_file)
  else
    cmd = ghci_cmd
  end

  local current_win = vim.api.nvim_get_current_win()

  vim.cmd 'belowright split'
  vim.cmd 'resize 15'

  M.ghci_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(M.ghci_buf)

  -- Reset output state
  M.output_buffer = {}
  M.pending_check = false

  M.ghci_chan = vim.fn.termopen(cmd, {
    on_stdout = on_stdout,
    on_stderr = on_stdout, -- Errors also come through stderr
    on_exit = function()
      M.ghci_chan = nil
      M.ghci_buf = nil
      M.output_buffer = {}
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
    cmd = cmd .. ' ' .. vim.fn.shellescape(boot_file)
  end

  local current_win = vim.api.nvim_get_current_win()

  vim.cmd 'belowright vsplit'

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
  M.output_buffer = {}
end

function M.close_sc()
  if buf_valid(M.sc_buf) then
    vim.api.nvim_buf_delete(M.sc_buf, { force = true })
  end
  M.sc_chan = nil
  M.sc_buf = nil
end

--- Set callback for GHCi output processing
---@param callback fun(output: string)
function M.set_output_callback(callback)
  M.on_output = callback
end

return M
