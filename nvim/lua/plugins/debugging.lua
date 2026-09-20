return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"igorlfs/nvim-dap-view",
			{
				"mason-org/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					table.insert(opts.ensure_installed, "js-debug-adapter")
					table.insert(opts.ensure_installed, "firefox-debug-adapter")
				end,
			},
		},
		config = function()
			local dap = require("dap")
			local dapview = require("dap-view")

			-- -----------------------------
			-- DAP View setup
			-- -----------------------------
			dapview.setup({
				winbar = {
					sections = { "scopes", "breakpoints", "watches", "console", "threads", "repl" },
					default_section = "scopes",
				},
				windows = {
					size = 0.3,
					terminal = {
						hide = true,
					},
				},
			})

			dap.listeners.before.attach.dapview_config = function()
				dapview.open()
			end
			dap.listeners.before.launch.dapview_config = function()
				dapview.open()
			end
			dap.listeners.before.event_terminated.dapview_config = function()
				dapview.close()
			end
			dap.listeners.before.event_exited.dapview_config = function()
				dapview.close()
			end

			-- -----------------------------
			-- JS/TS/React adapters (via Mason-installed adapters)
			-- -----------------------------
			if not dap.adapters["pwa-node"] then
				dap.adapters["pwa-node"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "js-debug-adapter",
						args = { "${port}" },
					},
				}
			end

			if not dap.adapters["pwa-chrome"] then
				dap.adapters["pwa-chrome"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "js-debug-adapter",
						args = { "${port}" },
					},
				}
			end

			if not dap.adapters["firefox"] then
				dap.adapters["firefox"] = {
					type = "executable",
					command = "node",
					args = {
						vim.fn.stdpath("data") .. "/mason/packages/firefox-debug-adapter/dist/adapter.bundle.js",
					},
				}
			end

			if not dap.adapters["node"] then
				dap.adapters["node"] = function(cb, config)
					config.type = "pwa-node"
					local nativeAdapter = dap.adapters["pwa-node"]
					if type(nativeAdapter) == "function" then
						nativeAdapter(cb, config)
					else
						cb(nativeAdapter)
					end
				end
			end

			-- Maps an open src/**/*.ts file to its compiled dist/**/*.js counterpart
			local function ts_to_compiled_js()
				local cwd = vim.fn.getcwd()
				vim.fn.system("npx tsc -p " .. cwd) -- blocking build
				local file = vim.fn.expand("%:p")
				local rel = file:gsub(vim.pesc(cwd .. "/src/"), "")
				rel = rel:gsub("%.tsx?$", ".js")
				return cwd .. "/dist/" .. rel
			end

			-- -----------------------------
			-- Vite dev server helpers (for React/Vite "Launch browser" flow)
			-- -----------------------------
			local vite_port = 5173 -- adjust if your vite.config sets a different port
			local vite_url = "http://localhost:" .. vite_port
			local firefox_executable = "/usr/bin/firefox-developer-edition" -- check with `which firefox`, adjust if different

			local function is_vite_running()
				local code = vim.fn.system({ "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", vite_url })
				return code ~= "000"
			end

			local function start_vite_if_needed()
				if is_vite_running() then
					return
				end
				vim.notify("Starting vite dev server...", vim.log.levels.INFO)
				vim.fn.jobstart({ "npm", "run", "dev" }, {
					cwd = vim.fn.getcwd(),
					detach = true,
				})
				local ready = vim.wait(15000, is_vite_running, 250)
				if not ready then
					vim.notify("Vite dev server didn't come up in time", vim.log.levels.WARN)
				end
			end

			-- One-button: ensure vite is running, then launch Firefox attached to it
			local function launch_vite_and_debug_firefox()
				start_vite_if_needed()
				dap.run({
					type = "firefox",
					request = "launch",
					name = "Launch Firefox against Vite dev server",
					url = vite_url,
					webRoot = "${workspaceFolder}",
					firefoxExecutable = firefox_executable,
					reAttach = true,
				})
			end

			-- Same, but Chrome (kept as a fallback option)
			local function launch_vite_and_debug_chrome()
				start_vite_if_needed()
				dap.run({
					type = "pwa-chrome",
					request = "launch",
					name = "Launch Chrome against Vite dev server",
					url = vite_url,
					webRoot = "${workspaceFolder}",
					sourceMaps = true,
					protocol = "inspector",
					userDataDir = false,
				})
			end

			-- -----------------------------
			-- Configurations for JS/TS/React
			-- -----------------------------
			local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
			local resolve_sourcemap_locations = {
				"${workspaceFolder}/**",
				"!**/node_modules/**",
			}

			for _, lang in ipairs(js_filetypes) do
				dap.configurations[lang] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch server (tsx)",
						runtimeExecutable = "${workspaceFolder}/node_modules/.bin/tsx",
						runtimeArgs = { "${workspaceFolder}/src/index.ts" },
						cwd = "${workspaceFolder}",
						env = { NODE_ENV = "development" },
						sourceMaps = true,
						protocol = "inspector",
						console = "integratedTerminal",
						resolveSourceMapLocations = resolve_sourcemap_locations,
						skipFiles = { "<node_internals>/**" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file (tsx)",
						runtimeExecutable = "${workspaceFolder}/node_modules/.bin/tsx",
						runtimeArgs = { "${file}" },
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						protocol = "inspector",
						console = "integratedTerminal",
						resolveSourceMapLocations = resolve_sourcemap_locations,
						skipFiles = { "<node_internals>/**" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Build + launch compiled JS (tsc)",
						program = ts_to_compiled_js,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						protocol = "inspector",
						console = "integratedTerminal",
						outFiles = { "${workspaceFolder}/dist/**/*.js" },
						resolveSourceMapLocations = resolve_sourcemap_locations,
						skipFiles = { "<node_internals>/**" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file (plain JS)",
						program = "${file}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						skipFiles = { "<node_internals>/**" },
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach to process",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
					{
						type = "firefox",
						request = "launch",
						name = "Launch Firefox (Vite, assumes dev server running)",
						url = vite_url,
						webRoot = "${workspaceFolder}",
						firefoxExecutable = firefox_executable,
						reAttach = true,
					},
					{
						type = "pwa-chrome",
						request = "launch",
						name = "Launch Chrome (Vite, assumes dev server running)",
						url = vite_url,
						webRoot = "${workspaceFolder}",
						sourceMaps = true,
						protocol = "inspector",
						userDataDir = false,
					},
				}
			end

			-- -----------------------------
			-- Keymaps
			-- -----------------------------
			local opts = { noremap = true, silent = true }

			vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, opts)
			vim.keymap.set("n", "<leader>dc", dap.continue, opts)
			vim.keymap.set("n", "<leader>ds", dap.step_over, opts)
			vim.keymap.set("n", "<leader>di", dap.step_into, opts)
			vim.keymap.set("n", "<leader>du", dap.step_out, opts)

			-- One-button vite + browser launches
			vim.keymap.set("n", "<leader>dV", launch_vite_and_debug_firefox, opts)
			vim.keymap.set("n", "<leader>dC", launch_vite_and_debug_chrome, opts)

			vim.keymap.set("n", "<leader>do", "<cmd>DapViewToggle<CR>", opts)
			vim.keymap.set({ "n", "v" }, "<leader>dh", "<cmd>DapViewHover<CR>", opts)
			vim.keymap.set({ "n", "v" }, "<leader>dH", "<cmd>DapViewHover!<CR>", opts)
			vim.keymap.set({ "n", "v" }, "<leader>dw", "<cmd>DapViewWatch<CR>", opts)

			vim.keymap.set("n", "<leader>dvs", "<cmd>DapViewJump scopes<CR>", opts)
			vim.keymap.set("n", "<leader>dvb", "<cmd>DapViewJump breakpoints<CR>", opts)
			vim.keymap.set("n", "<leader>dvc", "<cmd>DapViewJump console<CR>", opts)
			vim.keymap.set("n", "<leader>dvr", "<cmd>DapViewJump repl<CR>", opts)
			vim.keymap.set("n", "<leader>dvt", "<cmd>DapViewJump threads<CR>", opts)
		end,
	},
}
