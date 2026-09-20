vim.filetype.add({
	pattern = {
		[".*%.component%.html"] = "htmlangular",
		[".*%.component%.css"] = "css", -- keep css working too
	},
})
