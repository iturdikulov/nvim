local df_open = false

return {
	{
		"sindrets/diffview.nvim",
		keys = {
			{
				"<leader>gd",
				function()
					if df_open then
						vim.cmd("DiffviewClose")
						df_open = false
					else
						vim.cmd("DiffviewOpen")
						df_open = true
					end
				end,
				desc = "Toggle Diffview",
			},
			{
				"<leader>gh",
				"<cmd>DiffviewFileHistory<CR>",
				desc = "Diff File History",
			},
			{
				"<leader>gl",
				"<cmd>DiffviewToggleFiles<CR>",
				desc = "Toggle File Panel",
			},
			{
				"<leader>gf",
				"<cmd>DiffviewFocusFiles<CR>",
				desc = "Focus File Panel",
			},
		},
	},
}
