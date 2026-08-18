return {
	"paradoxical-dev/zeal.nvim",
	event = "VeryLazy",
	dependencies = { "folke/snacks.nvim" },
	keys = {
		{
			"<leader>fd",
			function()
				require("zeal").search_ft(vim.fn.expand("<cword>"))
			end,
			desc = "Search Zeal docs",
		},
	},
	opts = {
		browser = "lynx",
		picker = {
			type = "snacks",
			snacks = {
				layout = "select",
			},
		},
		ft_map = {
			python = { "python_3", "flask", "pytest" },
			javascript = { "javascript", "nodejs", "vuejs" },
			javascriptreact = { "javascript", "react" },
			typescript = { "typescript" },
			typescriptreact = { "typescript", "react" },
			vue = { "vuejs", "typescript", "javascript" },
		},
	},
}
