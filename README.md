# vim-tidal-lua

A pure Lua port of [vim-tidal](https://github.com/tidalcycles/vim-tidal) for Neovim. Provides [TidalCycles](https://tidalcycles.org/) live coding integration.

## Requirements

- Neovim 0.11+
- GHCi with TidalCycles installed
- SuperDirt (for audio output)
- SuperCollider (optional, for launching SuperDirt from Neovim)

## Installation

### lazy.nvim

```lua
{
  "vaporif/vim-tidal-lua",
  ft = "tidal",
  opts = {},
}
```

### packer.nvim

```lua
use {
  "vaporif/vim-tidal-lua",
  ft = "tidal",
  config = function()
    require("tidal").setup()
  end
}
```

### Manual

Clone to `~/.local/share/nvim/site/pack/plugins/start/vim-tidal-lua`

## Configuration

```lua
require("tidal").setup({
  ghci = "ghci",           -- GHCi executable
  boot = nil,              -- Boot file (auto-discovered if nil)
  flash_duration = 150,    -- Flash feedback duration in ms (0 to disable)
  sc_enable = false,       -- Enable SuperCollider terminal
  sclang = "sclang",       -- sclang executable
  sc_boot = nil,           -- SuperCollider boot file
  no_mappings = false,     -- Disable default key mappings
  diagnostics = true,      -- Show GHCi errors as Neovim diagnostics
})
```

## Key Mappings

Default mappings in `.tidal` files:

| Mapping | Mode | Action |
|---------|------|--------|
| `<C-e>` | n/i | Send paragraph |
| `<C-e>` | x | Send selection |
| `<localleader>s` | n | Send line |
| `<localleader>s` | x | Send selection |
| `<localleader>ss` | n | Send paragraph |
| `<C-h>` | n | Hush (silence all) |
| `<localleader>h` | n | Hush |
| `<localleader>1-9` | n | Silence stream d1-d9 |
| `<localleader>s1-9` | n | Play stream d1-d9 |

Set `no_mappings = true` to define your own mappings.

## Commands

| Command | Description |
|---------|-------------|
| `:TidalSend` | Send current line or range |
| `:TidalSend1 {text}` | Send literal text |
| `:TidalHush` | Silence all streams |
| `:TidalSilence {n}` | Silence stream n |
| `:TidalPlay {n}` | Find and play stream n |
| `:TidalStart` | Start GHCi terminal |
| `:TidalStop` | Stop GHCi terminal |
| `:TidalGenerateCompletions [path]` | Generate dirt-samples list |

## Custom Boot Files

The plugin searches parent directories for:
- `BootTidal.hs`
- `Tidal.ghci`
- `boot.tidal`

Or set explicitly:
```lua
require("tidal").setup({
  boot = "/path/to/custom/boot.hs"
})
```

Or use the `TIDAL_BOOT_PATH` environment variable.

## SuperCollider Integration

Launch SuperCollider alongside GHCi:

```lua
require("tidal").setup({
  sc_enable = true,
})
```

## Lua API

```lua
local tidal = require("tidal")

tidal.send(text)         -- Send text to GHCi
tidal.send_line(count)   -- Send line(s)
tidal.send_paragraph()   -- Send paragraph
tidal.send_visual()      -- Send visual selection
tidal.hush()             -- Silence all
tidal.silence(n)         -- Silence stream n
tidal.play(n)            -- Find and play stream n
tidal.open_ghci()        -- Open GHCi terminal
tidal.close_ghci()       -- Close GHCi terminal
tidal.clear_diagnostics() -- Clear error diagnostics

-- Statusline
tidal.is_running()       -- Check if GHCi is running
tidal.is_sc_running()    -- Check if SuperCollider is running
tidal.get_status()       -- Get status table {running, sc_running, boot_file}
tidal.statusline()       -- Get formatted string: "Tidal", "Tidal+SC", or ""
```

## Statusline Integration

### lualine.nvim

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      { function() return require("tidal").statusline() end },
    },
  },
})
```

### heirline.nvim

```lua
{
  condition = function() return require("tidal").is_running() end,
  provider = function() return require("tidal").statusline() end,
}
```

## License

MIT
