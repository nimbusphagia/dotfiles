return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	dependencies = {
		"mfussenegger/nvim-dap",
		"williamboman/mason.nvim",
	},
	config = function()
		local jdtls_ok, jdtls = pcall(require, "jdtls")
		if not jdtls_ok then
			return
		end

		local mason_registry = require("mason-registry")
		local jdtls_pkg = mason_registry.get_package("jdtls")
		local jdtls_path = jdtls_pkg:get_install_path()

		local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

		local SYSTEM = "linux"
		if vim.fn.has("mac") == 1 then
			SYSTEM = "mac"
		elseif vim.fn.has("win32") == 1 then
			SYSTEM = "win"
		end
		local os_config = jdtls_path .. "/config_" .. SYSTEM

		local lombok_jar = jdtls_path .. "/lombok.jar"

		-- one workspace per project, based on cwd name, so state doesn't bleed across projects
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

		local function get_bundles()
			local bundles = {}
			local debug_ok, debug_pkg = pcall(mason_registry.get_package, "java-debug-adapter")
			if debug_ok then
				vim.list_extend(
					bundles,
					vim.split(
						vim.fn.glob(
							debug_pkg:get_install_path() .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"
						),
						"\n"
					)
				)
			end
			local test_ok, test_pkg = pcall(mason_registry.get_package, "java-test")
			if test_ok then
				vim.list_extend(
					bundles,
					vim.split(vim.fn.glob(test_pkg:get_install_path() .. "/extension/server/*.jar"), "\n")
				)
			end
			return bundles
		end

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if cmp_ok then
			capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
		end

		local config = {
			cmd = {
				"jdtls",
             "--jvm-arg=-javaagent:" .. lombok_jar,
				"-configuration",
				vim.fn.stdpath("cache") .. "/jdtls",
				"-data",
				workspace_dir,
			},
			root_dir = require("jdtls.setup").find_root({ "pom.xml", "build.gradle", "build.gradle.kts", ".git" }),
			capabilities = capabilities,
			settings = {
				java = {
					signatureHelp = { enabled = true },
					completion = { favoriteStaticMembers = {} },
				},
			},
			init_options = {
				bundles = get_bundles(),
			},
			on_attach = function(client, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

				-- jdtls-specific extras
				vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, opts)
				vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, opts)
				vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, opts)
				vim.keymap.set("v", "<leader>jm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], opts)

				jdtls.setup_dap({ hotcodereplace = "auto" })
			end,
		}

		jdtls.start_or_attach(config)
	end,
}
