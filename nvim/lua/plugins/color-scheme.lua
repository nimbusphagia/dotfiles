return {
  {
    "EdenEast/nightfox.nvim",
    priority = 1000, -- load before other UI stuff
    config = function()
      vim.cmd.colorscheme("nightfox")
    end,
  },
}
