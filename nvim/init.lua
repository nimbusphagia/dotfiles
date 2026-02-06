vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.expandtab = true

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
