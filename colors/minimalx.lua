vim.o.background = "dark"
vim.cmd("hi clear")

if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "minimalx"

require("minimalx.dark").set()
