return {
	{
		"dlyongemallo/diffview-plus.nvim",
		version = "*",
		main = "diffview",
		opts = {
            enhanced_diff_hl = false,
            view = {
                default = {
                    focus_diff = true,
                    layout = "diff1_inline",
                },
            },
            inline = {
                style = "unified",
                deletion_treesitter = true,
            },
            file_panel = {
                win_config = {
                    width = 23,
                },
            },
		},
		cmd = {
			"DiffviewOpen",
			"DiffviewToggle",
			"DiffviewDiffFiles",
			"DiffviewMergeFiles",
			"DiffviewDiffDirs",
			"DiffviewFileHistory",
			"DiffviewClose",
			"DiffviewFocusFiles",
			"DiffviewToggleFiles",
			"DiffviewRefresh",
			"DiffviewLog",
		},
		keys = {
			{
				"<leader>gd",
				"<cmd>DiffviewToggle<CR>",
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
