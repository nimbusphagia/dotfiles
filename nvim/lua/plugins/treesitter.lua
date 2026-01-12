-- lua/plugins/treesitter.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },  -- lazy-load only when opening a file
    config = function()
      -- safe require, prevents crashes if plugin isn't installed yet
      local ok, tsconfigs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        return
      end

      tsconfigs.setup({
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}

