return {
  -- Mason core
  {
    "williamboman/mason.nvim",
    keys = {
      { "<leader>m", "<cmd>Mason<CR>", desc = "Open Mason UI" },
    },
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason-LSP bridge
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "lua_ls", "rust_analyzer", },       -- preinstalled servers
    },
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    config = function()
      local on_attach = function(_, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
      end

      -- Optionally add nvim-cmp capabilities
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      local mason_lspconfig = require("mason-lspconfig")
      local servers = mason_lspconfig.get_installed_servers()       -- get all installed servers

      for _, server in ipairs(servers) do
        local server_opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        -- Special config for lua_ls
        if server == "lua_ls" then
          server_opts.settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
            },
          }
        end

        vim.lsp.config(server, server_opts)
        vim.lsp.enable(server)
      end
    end,
  },
}
