local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, 'TidalKeyword', { link = 'Keyword' })
  vim.api.nvim_set_hl(0, 'TidalType', { link = 'Type' })
  vim.api.nvim_set_hl(0, 'TidalOperator', { link = 'Operator' })
  vim.api.nvim_set_hl(0, 'TidalString', { link = 'String' })
  vim.api.nvim_set_hl(0, 'TidalComment', { link = 'Comment' })
  vim.api.nvim_set_hl(0, 'TidalNumber', { link = 'Number' })
  vim.api.nvim_set_hl(0, 'TidalFunction', { link = 'Function' })
  vim.api.nvim_set_hl(0, 'TidalStream', { link = 'Special' })
  vim.api.nvim_set_hl(0, 'TidalMiniNotation', { link = 'String' })

  vim.cmd [[
    syntax clear

    " Comments
    syntax match TidalComment "--.*$"
    syntax region TidalComment start="{-" end="-}"

    " Strings
    syntax region TidalString start=+"+ skip=+\\"+ end=+"+

    " Numbers
    syntax match TidalNumber "\<\d\+\(\.\d\+\)\?\>"
    syntax match TidalNumber "\<0[xX][0-9a-fA-F]\+\>"

    " Haskell keywords
    syntax keyword TidalKeyword let in where do if then else case of
    syntax keyword TidalKeyword import module
    syntax keyword TidalKeyword True False

    " Types
    syntax match TidalType "\<[A-Z][a-zA-Z0-9_']*\>"

    " Operators
    syntax match TidalOperator "[|$#<>*+\-/=&@~!?%^]"
    syntax match TidalOperator "\.\."
    syntax match TidalOperator "<|"
    syntax match TidalOperator "|>"
    syntax match TidalOperator "|<"
    syntax match TidalOperator ">|"
    syntax match TidalOperator "<\~"
    syntax match TidalOperator "\~>"

    " Tidal streams
    syntax match TidalStream "\<d[1-9]\>"
    syntax match TidalStream "\<d1[0-6]\>"
    syntax match TidalStream "\<p\s*\d\+\>"
    syntax match TidalStream "\<p\s*\"[^\"]*\"\>"

    " Common Tidal functions
    syntax keyword TidalFunction sound s n note gain amp pan speed
    syntax keyword TidalFunction fast slow rev palindrome
    syntax keyword TidalFunction every sometimes often rarely
    syntax keyword TidalFunction stack cat randcat fastcat slowcat
    syntax keyword TidalFunction jux juxBy spread spreadChoose
    syntax keyword TidalFunction striate striateBy chop gap
    syntax keyword TidalFunction degrade degradeBy
    syntax keyword TidalFunction orbit room size delay
    syntax keyword TidalFunction crush coarse shape
    syntax keyword TidalFunction hush silence
    syntax keyword TidalFunction cps setcps
    syntax keyword TidalFunction run irand rand choose
    syntax keyword TidalFunction struct euclid euclidFull
    syntax keyword TidalFunction bite chew shuffle scramble
    syntax keyword TidalFunction arp arpeggiate
    syntax keyword TidalFunction mask fit
    syntax keyword TidalFunction scale scaleList
    syntax keyword TidalFunction chord chordList
    syntax keyword TidalFunction legato sustain attack release
    syntax keyword TidalFunction vowel cut cutoff resonance
    syntax keyword TidalFunction begin end loop loopAt
    syntax keyword TidalFunction whenmod when
    syntax keyword TidalFunction superimpose layer off
    syntax keyword TidalFunction chunk hurry stretch compress zoom
  ]]
end

return M
