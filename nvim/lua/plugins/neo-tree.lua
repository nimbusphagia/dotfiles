return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,

        filesystem = {
          follow_current_file = { enabled = true }, -- ✅ updated for v3.x
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
          },
        },

        window = {
          mappings = {
            ["l"] = "open",       -- press l to open the file
            ["<CR>"] = "open",    -- enter also opens the file
            ["h"] = "close_node", -- optional: h collapses directory
          },
        },
      })
      vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
      vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
    end,
  },

  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- ensures this loads after Neo-tree
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },

  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
