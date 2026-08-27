return {
	{
		"dlyongemallo/diffview-plus.nvim",
		version = "*",
		main = "diffview",
		opts = {
            watch_index = true,
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
		config = function(_, opts)
			require("diffview").setup(opts)

			local group = vim.api.nvim_create_augroup("UserDiffviewWatchRefresh", { clear = true })
			local refresh_timer
			local repo_watch ---@type uv.uv_fs_event_t?

			local function refresh_diffview()
				local lib = require("diffview.lib")
				local view = lib.get_current_view()
				if not view or view.class.name ~= "DiffView" or not view:is_cur_tabpage() then
					return
				end
				require("diffview.actions").refresh_files()
			end

			local function schedule_refresh()
				if refresh_timer then
					vim.fn.timer_stop(refresh_timer)
				end
				refresh_timer = vim.fn.timer_start(300, refresh_diffview, { ["repeat"] = 1 })
			end

			local function stop_repo_watch()
				if repo_watch and not repo_watch:is_closing() then
					repo_watch:stop()
					repo_watch:close()
				end
				repo_watch = nil
			end

			local function has_open_diffview()
				for _, view in ipairs(require("diffview.lib").views) do
					if view.class.name == "DiffView" then
						return true
					end
				end
				return false
			end

			local function start_repo_watch()
				stop_repo_watch()
				local path = vim.fn.getcwd()
				if path == "" or vim.uv.fs_stat(path) == nil then
					return
				end

				local watch = assert(vim.uv.new_fs_event())
				local ok, err = watch:start(path, { recursive = true }, function(watch_err, filename)
					if watch_err or not filename then
						return
					end
					if filename:find("%.git", 1, true) then
						return
					end
					schedule_refresh()
				end)
				if not ok then
					watch:close()
					vim.notify(
						("Diffview: fs watch failed for %s: %s"):format(path, err),
						vim.log.levels.WARN
					)
					return
				end
				repo_watch = watch
			end

			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = { "DiffviewViewOpened", "DiffviewViewClosed" },
				callback = function(ev)
					vim.schedule(function()
						if ev.match == "DiffviewViewOpened" then
							local view = require("diffview.lib").get_current_view()
							if view and view.class.name == "DiffView" then
								start_repo_watch()
							end
						elseif not has_open_diffview() then
							stop_repo_watch()
						end
					end)
				end,
			})
		end,
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
