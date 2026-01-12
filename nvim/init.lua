-- Use 2 spaces per indent (common for Lua, JavaScript)
vim.o.tabstop = 2        -- visual width of a tab character
vim.o.shiftwidth = 2     -- width for autoindent and >> <<
vim.o.softtabstop = 2    -- insert mode tab key behaves like 2 spaces
vim.o.expandtab = true   -- convert tabs to spaces

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.filetype.add({
  extension = {
    ejs = "html",
  },
})

require("config.lazy")

vim.keymap.set("n", "<leader>l", function()
  require("lazy").home()
end, { desc = "Open Lazy.nvim" })



