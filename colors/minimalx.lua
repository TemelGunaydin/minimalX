vim.cmd("hi clear")

if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "minimalx"

-- MinimalX is designed for dark mode only
local minimalx_dark = require'minimalx.dark'
minimalx_dark.set()
