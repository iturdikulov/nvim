--- Корень git-репозитория или cwd — scope для recent files на dashboard.
local function project_scope()
	local ok, Snacks = pcall(require, "snacks")
	if ok then
		return Snacks.git.get_root(vim.fn.getcwd()) or vim.fn.getcwd()
	end
	return vim.fn.getcwd()
end

---@param file string
local function file_in_project_scope(file)
	local scope = vim.fs.normalize(project_scope())
	file = vim.fs.normalize(file)
	return file == scope or file:sub(1, #scope + 1) == scope .. "/"
end

local function pick_project_oldfiles()
	local scope = vim.fs.normalize(project_scope())
	require("snacks").dashboard.pick("oldfiles", { filter = { [scope] = true } })
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		dashboard = {
			width = 90,
			enabled = true,
			preset = {
				-- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
				---@type fun(cmd:string, opts:table)|nil
				pick = nil,
				-- Used by the `keys` section to show keymaps.
				-- Set your custom keymaps here.
				-- When using a function, the `items` argument are the default keymaps.
				---@type snacks.dashboard.Item[]
				keys = {
					{
						icon = " ",
						key = "f",
						desc = "Find File",
						action = ":lua Snacks.dashboard.pick('files')",
					},
					{
						icon = " ",
						key = "n",
						desc = "New File",
						action = ":ene | startinsert",
					},
					{
						icon = "󰥩 ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = pick_project_oldfiles,
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{
						icon = " ",
						key = "s",
						desc = "Restore Session",
						section = "session",
					},
					{
						icon = "󰒲 ",
						key = "L",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{
					icon = " ",
					title = "Keymaps",
					section = "keys",
					indent = 2,
					padding = 1,
				},
				{
					icon = " ",
					title = "Recent Files",
					section = "recent_files",
					indent = 2,
					padding = 1,
					limit = 20,
					filter = file_in_project_scope,
				},
				{ section = "startup" },
			},
		},
		explorer = { replace_netrw = true },
		bigfile = {
			enabled = true,
		},
		indent = {
			enabled = true,
			animate = {
				enabled = false,
			},
		},
		gitbrowse = {
			enabled = true,
		},
		lazygit = {
			enabled = true,
			configure = true,
		},
		notifier = {
			enabled = true,
			timeout = 5000,
			icons = {
				error = "ERROR ",
				warn = "WARNING ",
				info = "INFO ",
				debug = "DEBUG ",
				trace = "TRACE ",
			},
		},
		quickfile = { enabled = true },
		scope = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		terminal = {
			bo = {
				filetype = "snacks_terminal",
			},
			wo = {},
			stack = true, -- when enabled, multiple split windows with the same position will be stacked together (useful for terminals)
			keys = {
				q = "hide",
				gf = function(self)
					local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
					if f == "" then
						Snacks.notify.warn("No file under cursor")
					else
						self:hide()
						vim.schedule(function()
							vim.cmd("e " .. f)
						end)
					end
				end,
				term_normal = {
					"<esc>",
					function(self)
						self.esc_timer = self.esc_timer
							or (vim.uv or vim.loop).new_timer()
						if self.esc_timer:is_active() then
							self.esc_timer:stop()
							vim.cmd("stopinsert")
						else
							self.esc_timer:start(200, 0, function() end)
							return "<esc>"
						end
					end,
					mode = "t",
					expr = true,
					desc = "Double escape to normal mode",
				},
			},
		},
		styles = {
			zen = {
				minimal = true,
				width = 80,
				backdrop = { transparent = false },
				wo = {
					wrap = true,
					linebreak = true,
				},
			},
		},
		zen = {
			toggles = {
				dim = false,
			},
		},
	},
	keys = {
		-- dashboard (`<leader>D` занят под "_d в remap.lua)
		{
			"<leader>H",
			function()
				Snacks.dashboard()
			end,
			desc = "Dashboard",
		},
		-- Other
		{
			"<leader>pv",
			function()
				Snacks.explorer()
			end,
			desc = "File Explorer",
		},
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>n",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>cb",
			function()
				require("config.buffers").delete()
			end,
			desc = "[C]lose [b]uffer",
		},
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File (LSP)",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse.open({ what = "commit" })
			end,
			desc = "Git Browse Commit",
			mode = { "n", "v" },
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gG",
			function()
				Snacks.lazygit({
					args = {
						"--git-dir=" .. vim.fn.expand("~/.local/share/yadm/repo.git"),
						"--work-tree=" .. vim.fn.expand("~"),
					},
				})
			end,
			desc = "Lazygit (yadm)",
		},
		{
			"<leader>T",
			function()
				Snacks.terminal.toggle()
			end,
			desc = "Toggle Terminal",
		},
		{
			-- Makefile Runner
			"<leader>o",
			function()
				local targets = {}
				local makefile = vim.fn.getcwd() .. "/Makefile"

				if vim.uv.fs_stat(makefile) then
					local file = io.open(makefile, "r")
					if file then
						for line in file:lines() do
							if line:match("^[^# ]+") then
								local target = line:match("^([^:]+):$")
								if target and not target:match("%%") then
									table.insert(targets, target)
								end
							end
						end
						file:close()
					end
				end

				if #targets > 0 then
					local menu = { "Select make target:" }
					for i, target in ipairs(targets) do
						table.insert(menu, string.format("%d. %s", i, target))
					end
					local choice = vim.fn.inputlist(menu)
					if choice > 0 and choice <= #targets then
						local target = targets[choice]
						Snacks.terminal.toggle(
							"make " .. target,
							{ win = { position = "bottom" } }
						)
					end
				end
			end,
			desc = "Run Make Target",
		},
		{
			"<leader>gb",
			function()
				Snacks.git.blame_line()
			end,
			desc = "Git Blame Line",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss Notifications",
		},
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command

				local Snacks = require("snacks")

				-- dashboard / picker keys при русской раскладке
				local ok, lmu = pcall(require, "langmapper.utils")
				if ok and Snacks.util and Snacks.util.normkey then
					local normkey_orig = Snacks.util.normkey
					Snacks.util.normkey = function(key)
						if key then
							key = lmu.translate_keycode(key, "default", "ru")
						end
						return normkey_orig(key)
					end
				end

				-- Create some toggle mappings
				Snacks.toggle
					.option("spell", { name = "Spelling" })
					:map("<leader>us")
				Snacks.toggle
					.option("wrap", { name = "Wrap" })
					:map("<leader>uw")
				Snacks.toggle
					.option("relativenumber", { name = "Relative Number" })
					:map("<leader>uL")
				Snacks.toggle.diagnostics():map("<leader>ud")
				Snacks.toggle.line_number():map("<leader>ul")
				Snacks.toggle
					.option("conceallevel", {
						off = 0,
						on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
					})
					:map("<leader>uc")
				Snacks.toggle.treesitter():map("<leader>uT")
				Snacks.toggle
					.option(
						"background",
						{ off = "light", on = "dark", name = "Dark Background" }
					)
					:map("<leader>ub")
				Snacks.toggle.inlay_hints():map("<leader>uh")
				Snacks.toggle.indent():map("<leader>ug")
				Snacks.toggle.dim():map("<leader>uD")
			end,
		})
	end,
}
