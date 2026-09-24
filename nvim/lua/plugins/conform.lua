return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					html = { "prettier" },
					htmlangular = { "prettier" },
					css = { "prettier" },
					typescript = { "prettier" },
					javascript = { "prettier" },
					json = { "prettier" },
					sql = { "sql_formatter" },
				},
				format_on_save = {
					timeout_ms = 2000,
					lsp_format = "fallback",
				},
			})
		end,
	},
}
