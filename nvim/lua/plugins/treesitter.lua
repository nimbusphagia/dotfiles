return {
  { "pantharshit00/vim-prisma", ft = "prisma" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "javascript",
        "prisma",
        "json",
        "html",
        "css",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
      },
      indent = { enable = true },
    },
  }
}
