local config = require 'tidal.config'
local syntax = require 'tidal.syntax'

syntax.setup()

vim.bo.commentstring = '-- %s'
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true

if config.options.no_mappings then
  return
end

local opts = { buffer = true, silent = true }

vim.keymap.set('n', '<C-e>', function()
  require('tidal').send_paragraph()
end, vim.tbl_extend('force', opts, { desc = 'Send paragraph to Tidal' }))

vim.keymap.set('i', '<C-e>', function()
  require('tidal').send_paragraph()
end, vim.tbl_extend('force', opts, { desc = 'Send paragraph to Tidal' }))

vim.keymap.set('x', '<C-e>', function()
  vim.cmd 'normal! '
  require('tidal').send_visual()
end, vim.tbl_extend('force', opts, { desc = 'Send selection to Tidal' }))

vim.keymap.set('n', '<localleader>s', function()
  require('tidal').send_line()
end, vim.tbl_extend('force', opts, { desc = 'Send line to Tidal' }))

vim.keymap.set('x', '<localleader>s', function()
  vim.cmd 'normal! '
  require('tidal').send_visual()
end, vim.tbl_extend('force', opts, { desc = 'Send selection to Tidal' }))

vim.keymap.set('n', '<localleader>ss', function()
  require('tidal').send_paragraph()
end, vim.tbl_extend('force', opts, { desc = 'Send paragraph to Tidal' }))

vim.keymap.set('n', '<C-h>', function()
  require('tidal').hush()
end, vim.tbl_extend('force', opts, { desc = 'Hush Tidal' }))

vim.keymap.set('n', '<localleader>h', function()
  require('tidal').hush()
end, vim.tbl_extend('force', opts, { desc = 'Hush Tidal' }))

for i = 1, 9 do
  vim.keymap.set('n', '<localleader>' .. i, function()
    require('tidal').silence(i)
  end, vim.tbl_extend('force', opts, { desc = 'Silence d' .. i }))

  vim.keymap.set('n', '<localleader>s' .. i, function()
    require('tidal').play(i)
  end, vim.tbl_extend('force', opts, { desc = 'Play d' .. i }))
end
