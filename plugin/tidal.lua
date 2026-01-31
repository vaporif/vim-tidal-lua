if vim.g.loaded_tidal then
  return
end
vim.g.loaded_tidal = true

if vim.fn.has 'nvim-0.7' == 0 then
  vim.notify('vim-tidal-lua requires Neovim 0.7+', vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command('TidalSend', function(opts)
  local tidal = require 'tidal'
  if opts.range > 0 then
    tidal.send_range(opts.line1, opts.line2)
  else
    tidal.send_line()
  end
end, { range = true, desc = 'Send current line or range to Tidal' })

vim.api.nvim_create_user_command('TidalSend1', function(opts)
  local tidal = require 'tidal'
  tidal.send(opts.args)
end, { nargs = 1, desc = 'Send literal text to Tidal' })

vim.api.nvim_create_user_command('TidalHush', function()
  require('tidal').hush()
end, { desc = 'Silence all Tidal streams' })

vim.api.nvim_create_user_command('TidalSilence', function(opts)
  require('tidal').silence(opts.args)
end, { nargs = 1, desc = 'Silence a specific Tidal stream' })

vim.api.nvim_create_user_command('TidalPlay', function(opts)
  require('tidal').play(opts.args)
end, { nargs = 1, desc = 'Find and play a specific Tidal stream' })

vim.api.nvim_create_user_command('TidalGenerateCompletions', function(opts)
  local path = opts.args ~= '' and opts.args or nil
  require('tidal').generate_completions(path)
end, { nargs = '?', desc = 'Generate dirt-samples dictionary' })

vim.api.nvim_create_user_command('TidalStart', function()
  require('tidal').open_ghci()
end, { desc = 'Start GHCi terminal' })

vim.api.nvim_create_user_command('TidalStop', function()
  require('tidal').close_ghci()
end, { desc = 'Stop GHCi terminal' })
