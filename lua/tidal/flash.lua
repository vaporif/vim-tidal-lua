local M = {}
local config = require 'tidal.config'

local ns_id = vim.api.nvim_create_namespace 'tidal_flash'

function M.flash_range(start_line, end_line)
  local duration = config.options.flash_duration
  if duration <= 0 then
    return
  end

  local buf = vim.api.nvim_get_current_buf()

  for line = start_line, end_line do
    vim.api.nvim_buf_add_highlight(buf, ns_id, 'Visual', line - 1, 0, -1)
  end

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    end
  end, duration)
end

return M
