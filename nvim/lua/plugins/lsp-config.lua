return {
	{
		"williamboman/mason.nvim",
		keys = {
			{ "<leader>m", "<cmd>Mason<CR>", desc = "Open Mason UI" },
		},
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"rust_analyzer",
				"angularls",
				"ts_ls",
				"cssls",
				"html",
				"cssmodules_ls",
				"sqls",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"prettier",
				"jdtls",
				"java-debug-adapter",
				"java-test",
				"google-java-format",
				"sql-formatter",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"nanotee/sqls.nvim",
		},
		config = function()
			local on_attach = function(client, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>f", function()
					require("conform").format({ bufnr = bufnr })
				end, opts)
			end

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if ok then
				capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
			end

			vim.lsp.config("pug", {
				cmd = { "pug-lsp" },
				filetypes = { "pug" },
				root_markers = { "package.json", ".git" },
				on_attach = on_attach,
				capabilities = capabilities,
			})
			vim.lsp.enable("pug")

			vim.lsp.config("sqls", {
				cmd = { "sqls" },
				filetypes = { "sql" },
				root_markers = { ".git" },
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false

					on_attach(client, bufnr)

					local has_sqls, sqls_helper = pcall(require, "sqls")
					if has_sqls then
						sqls_helper.on_attach(client, bufnr)
					end
				end,
			})
			vim.lsp.enable("sqls")

			local mason_lspconfig = require("mason-lspconfig")
			local servers = mason_lspconfig.get_installed_servers()

			for _, server in ipairs(servers) do
				if server ~= "sqls" then
					local opts = {
						on_attach = on_attach,
						capabilities = capabilities,
					}

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

					if server == "angularls" then
						local mason_data = vim.fn.stdpath("data")
							.. "/mason/packages/angular-language-server/node_modules/@angular/language-server"
						opts.cmd = {
							"ngserver",
							"--stdio",
							"--tsProbeLocations",
							mason_data,
							"--ngProbeLocations",
							mason_data,
						}
						opts.filetypes = { "typescript", "html", "typescriptreact", "htmlangular" }
						opts.root_dir = require("lspconfig.util").root_pattern("angular.json", "project.json")
						opts.on_new_config = function(new_config)
							new_config.cmd = opts.cmd
						end
					end

					if server == "html" then
						opts.capabilities = vim.tbl_deep_extend("force", capabilities, {
							textDocument = {
								completion = {
									completionItem = { snippetSupport = true },
								},
							},
						})
						opts.filetypes = { "html", "htmlangular" }
						opts.on_attach = function(client, bufnr)
							client.server_capabilities.documentFormattingProvider = false
							client.server_capabilities.documentRangeFormattingProvider = false
							on_attach(client, bufnr)
						end
					end

					if server == "cssls" then
						opts.capabilities = vim.tbl_deep_extend("force", capabilities, {
							textDocument = {
								completion = {
									completionItem = { snippetSupport = true },
								},
							},
						})
					end
					if server == "cssmodules_ls" then
						opts.filetypes = {
							"css",
							"scss",
							"sass",
							"javascript",
							"javascriptreact",
							"typescript",
							"typescriptreact",
						}
						opts.on_attach = function(client, bufnr)
							client.server_capabilities.definitionProvider = false
							on_attach(client, bufnr)
							vim.keymap.set(
								"n",
								"gi",
								vim.lsp.buf.implementation,
								{ noremap = true, silent = true, buffer = bufnr }
							)
						end
					end

					vim.lsp.config(server, opts)
					vim.lsp.enable(server)
				end
			end
		end,
	},
}
