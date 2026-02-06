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
      ensure_installed = {
        "lua_ls",
        "rust_analyzer",
        -- NOTE: pug is NOT included here on purpose
      },
    },
  },

  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    config = function()
      ------------------------------------------------------------------
      -- ON ATTACH
      ------------------------------------------------------------------
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)

        -- Format on save
        if client.supports_method("textDocument/formatting") then
          local group = vim.api.nvim_create_augroup(
            "LspFormatOnSave_" .. bufnr,
            { clear = true }
          )

          vim.api.nvim_create_autocmd("BufWritePre", {
            group = group,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end
      end

      ------------------------------------------------------------------
      -- CAPABILITIES (nvim-cmp)
      ------------------------------------------------------------------
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      ------------------------------------------------------------------
      -- CUSTOM SERVER: PUG
      ------------------------------------------------------------------
      vim.lsp.config("pug", {
        cmd = { "pug-lsp" }, -- or "pug-language-server"
        filetypes = { "pug" },
        root_markers = { "package.json", ".git" },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      vim.lsp.enable("pug")

      ------------------------------------------------------------------
      -- AUTO-SETUP MASON SERVERS
      ------------------------------------------------------------------
      local mason_lspconfig = require("mason-lspconfig")
      local servers = mason_lspconfig.get_installed_servers()

      for _, server in ipairs(servers) do
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        -- lua_ls specific config
        if server == "lua_ls" then
          opts.settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
              telemetry = { enable = false },
            },
          }
        end

        vim.lsp.config(server, opts)
        vim.lsp.enable(server)
      end
    end,
  },
}
