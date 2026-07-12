return {
	"glacambre/firenvim",
	build = ":call firenvim#install(0)",
	config = function()
		vim.api.nvim_create_autocmd("UIEnter", {
			pattern = "*",
			callback = function()
				vim.cmd(
					"if exists('g:started_by_firenvim')\nset guifont=monospace:h24\nendif"
				)
			end,
		})
	end,
}
