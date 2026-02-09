vim.api.nvim_create_augroup("DapGroup", { clear = true })

local function navigate(args)
	local buffer = args.buf

	local wid = nil
	local win_ids = vim.api.nvim_list_wins() -- Get all window IDs
	for _, win_id in ipairs(win_ids) do
		local win_bufnr = vim.api.nvim_win_get_buf(win_id)
		if win_bufnr == buffer then
			wid = win_id
		end
	end

	if wid == nil then
		return
	end

	vim.schedule(function()
		if vim.api.nvim_win_is_valid(wid) then
			vim.api.nvim_set_current_win(wid)
		end
	end)
end

local function create_nav_options(name)
	return {
		group = "DapGroup",
		pattern = string.format("*%s*", name),
		callback = navigate,
	}
end

return {
	{
		"mfussenegger/nvim-dap",
		lazy = false,
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
				"theHamsta/nvim-dap-virtual-text",
			},
		},
		config = function()
			local dap = require("dap")
			dap.set_log_level("DEBUG")

			-- virtual text
			require("nvim-dap-virtual-text").setup({})

			vim.keymap.set( "n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Conditional Breakpoint" })

			vim.keymap.set("n", "<leader>dp", function() dap.pause() end, { desc = "Debug: Pause" })
			vim.keymap.set("n", "<leader>ds", function() dap.session() end, { desc = "Debug: Session" })
			vim.keymap.set("n", "<leader>dt", function() dap.terminate() end, { desc = "Debug: Terminate" })
			vim.keymap.set("n", "<leader>dl", function() dap.run_last() end, { desc = "Debug: Run last" })
			vim.keymap.set( "n", "<leader>dr", dap.restart, { desc = "Debug: Restart Debugger" })

			vim.keymap.set( "n", "<F1>", dap.continue, { desc = "Debug: Continue until Breakpoint" })
			vim.keymap.set( "n", "<F2>", dap.step_into, { desc = "Debug: Step Into Details" })
			vim.keymap.set( "n", "<F3>", dap.step_over, { desc = "Debug: Step Over Instruction" })
			vim.keymap.set( "n", "<F4>", dap.step_out, { desc = "Debug: Step Out Details" })

			vim.keymap.set("n", "<leader>dg", function() dap.run_to_cursor() end, { desc = "Debug: Run to cursor" })
			vim.keymap.set("n", "<leader>dG", function() dap.goto_() end, { desc = "Debug: Go to line (no execute)" })
			vim.keymap.set("n", "<leader>dj", function() dap.down() end, { desc = "Debug: down" })
			vim.keymap.set("n", "<leader>dk", function() dap.up() end, { desc = "Debug: Up" })

			-- Hover functionality
			vim.keymap.set("n", "<leader>dh", function()
				require("dap.ui.widgets").hover()
			end, { desc = "Debug: Hover" })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dap-float",
				callback = function()
					vim.api.nvim_buf_set_keymap(
						0,
						"n",
						"q",
						"<cmd>close!<CR>",
						{ noremap = true, silent = true }
					)
				end,
			})

			vim.keymap.set( "n", "<F6>", dap.step_back, { desc = "Debug: Step Back in Time" })


			-- Add pwa-node adapter
			-- dap.adapters["pwa-node"] = {
			--	type = "server",
			--	host = "localhost",
			--	port = "${port}",
			--	executable = {
			--		command = "node",
			--		args = {
			--			require("mason-registry")
			--				.get_package("js-debug-adapter")
			--				:get_install_path()
			--				.. "/js-debug/src/dapDebugServer.js",
			--			"${port}",
			--		},
			--	},
			--	options = {
			--		sourceMapPathOverrides = {
			--			["webpack:///./*"] = "${workspaceFolder}/*",
			--		},
			--	},
			-- }

			-- Add alias for node-terminal to point to pwa-node
			dap.adapters["node-terminal"] = dap.adapters["pwa-node"]
			dap.adapters.chrome = {
				type = "executable",
				command = "node",
				args = {
					os.getenv("HOME")
						.. "/Desktop/software/vscode-chrome-debug/out/src/chromeDebug.js",
				}, -- TODO adjust
			}

			local js_based_languages = {
				"typescript",
				"javascript",
				"typescriptreact",
				"javascriptreact",
			}
			for _, language in ipairs(js_based_languages) do
				dap.configurations[language] = {
					{
						type = "chrome",
						request = "attach",
						program = "${file}",
						cwd = vim.fn.getcwd(),
						sourceMaps = true,
						protocol = "inspector",
						port = 9222,
						webRoot = "${workspaceFolder}",
					},
					{
						name = "Local: Next.js: launch and debug",
						type = "pwa-node",
						request = "launch",
						program = "${workspaceFolder}/node_modules/.bin/next",
						args = { "dev" },
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						skipFiles = { "<node_internals>/**", "node_modules/**" },
						runtimeArgs = { "--inspect" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Local: Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Local: Attach to Node process",
						processId = require("dap.utils").pick_process,
						cwd = vim.fn.getcwd(),
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Local: Auto Attach",
						skipFiles = { "<node_internals>/**" },
						cwd = vim.fn.getcwd(),
					},
				}
			end
		end,
	},

	{
		"igorlfs/nvim-dap-view",
		opts = {
			winbar = {
				show_keymap_hints = false,
				sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
				base_sections = {
					breakpoints = { label = "Breaks", keymap = "B" },
					scopes = { label = "Scope", keymap = "S" },
					exceptions = { label = "Exceptions", keymap = "E" },
					watches = { label = "Watch", keymap = "W" },
					threads = { label = "Threads", keymap = "T" },
					repl = { label = "REPL", keymap = "R" },
					sessions = { label = "Sessions", keymap = "K" },
					console = { label = "Console", keymap = "C" },
				},
			},
			windows = {
				-- `prev` is the last used position, might be nil
				position = function(prev)
					local wins = vim.api.nvim_tabpage_list_wins(0)

					-- Restores previous position if terminal is visible
					if
						vim.iter(wins):find(function(win)
							return vim.w[win].dapview_win_term
						end)
					then
						return prev
					end

					return vim.tbl_count(vim.iter(wins)
						:filter(function(win)
							local buf = vim.api.nvim_win_get_buf(win)
							local valid_buftype = vim.tbl_contains(
								{ "", "help", "prompt", "quickfix", "terminal" },
								vim.bo[buf].buftype
							)
							local dapview_win = vim.w[win].dapview_win
								or vim.w[win].dapview_win_term
							return valid_buftype and not dapview_win
						end)
						:totable()) > 1 and "below" or "right"
				end,
				size = function(pos)
					return pos == "below" and 0.25 or 0.4
				end,
				terminal = {
					-- `pos` is the position for the regular window
					position = function(pos)
						return pos == "below" and "right" or "below"
					end,
					size = 0.5,
				},
			},
		},
		config = function(_, opts)
			require("dap-view").setup(opts)

			local dap = require("dap")

			vim.keymap.set("n", "<leader>dv", function()
				vim.cmd("DapViewToggle")
			end, { desc = "Debug: Toggle DapView" })

			dap.listeners.before.attach.dapui_config = function()
				vim.cmd("DapViewOpen")
			end
			dap.listeners.before.launch.dapui_config = function()
				vim.cmd("DapViewOpen")
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				vim.cmd("DapViewClose")
			end
			dap.listeners.before.event_exited.dapui_config = function()
				vim.cmd("DapViewClose")
			end

			dap.listeners.after.event_initialized["set_exception_breakpoints"] = function()
				dap.defaults.python.exception_breakpoints = {'raised'} -- raised
			end
		end,
	},

	-- Python configuration
	{
		"mfussenegger/nvim-dap-python",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		ft = { "python" },
		config = function()
			local dap_python = require("dap-python")
			local dap = require("dap")
			local python_path = vim.fn.exepath("python3")
			vim.g.python3_host_prog = python_path

			dap_python.setup(vim.g.python3_host_prog)
			dap_python.test_runner = "pytest"

			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "module",
				console = "integratedTerminal",
				module = "src", -- edit this to be your app's main module
				cwd = "${workspaceFolder}",
			})

			table.insert(dap.configurations.python, {
				type = "python",
				request = "attach",
				name = "Attach to Docker",
				connect = {
					host = "127.0.0.1", -- Host where Docker port is exposed
					port = 5679, -- Port exposed in docker-compose
				},
				console = "integratedTerminal",
				-- Maps your local project root to the Docker container's workdir
				pathMappings = {
					{
						localRoot = vim.fn.getcwd(), -- or specific path like '/home/user/project'
						remoteRoot = "/apps/rtms-backend", -- Path inside the Docker container
					},
				},
			})
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = {
			"mfussenegger/nvim-dap",
			{
				"microsoft/vscode-js-debug",
				build = "npm ci --legacy-peer-deps && npm run compile",
			},
		},
	},
}
