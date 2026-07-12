vim.api.nvim_create_augroup("DapGroup", { clear = true })

--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
local function get_pkg_path(pkg, path)
	pcall(require, "mason")
	local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
	path = path or ""
	local ret = root .. "/packages/" .. pkg .. "/" .. path
	return ret
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

			vim.keymap.set(
				"n",
				"<leader>b",
				dap.toggle_breakpoint,
				{ desc = "Debug: Toggle Breakpoint" }
			)
			vim.keymap.set("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Conditional Breakpoint" })

			vim.keymap.set("n", "<leader>dp", function()
				dap.pause()
			end, { desc = "Debug: Pause" })
			vim.keymap.set("n", "<leader>ds", function()
				dap.session()
			end, { desc = "Debug: Session" })
			vim.keymap.set("n", "<leader>dt", function()
				dap.terminate()
			end, { desc = "Debug: Terminate" })
			vim.keymap.set("n", "<leader>dl", function()
				dap.run_last()
			end, { desc = "Debug: Run last" })
			vim.keymap.set("n", "<leader>dr", function()
				dap.restart()
			end, { desc = "Debug: Restart Debugger" })

			vim.keymap.set("n", "<leader>dR", function()
				vim.cmd("silent !/workspace/packages/rtms-backend/curl.sh &")
			end, { desc = "Debug: Restart Debugger" })

			vim.keymap.set(
				"n",
				"<F1>",
				dap.continue,
				{ desc = "Debug: Continue until Breakpoint" }
			)
			vim.keymap.set(
				"n",
				"<F2>",
				dap.step_into,
				{ desc = "Debug: Step Into Details" }
			)
			vim.keymap.set(
				"n",
				"<F3>",
				dap.step_over,
				{ desc = "Debug: Step Over Instruction" }
			)
			vim.keymap.set(
				"n",
				"<F4>",
				dap.step_out,
				{ desc = "Debug: Step Out Details" }
			)

			vim.keymap.set("n", "<leader>dg", function()
				dap.run_to_cursor()
			end, { desc = "Debug: Run to cursor" })
			vim.keymap.set("n", "<leader>dG", function()
				dap.goto_()
			end, { desc = "Debug: Go to line (no execute)" })
			vim.keymap.set("n", "<leader>dj", function()
				dap.down()
			end, { desc = "Debug: down" })
			vim.keymap.set("n", "<leader>dk", function()
				dap.up()
			end, { desc = "Debug: Up" })

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

			vim.keymap.set(
				"n",
				"<F6>",
				dap.step_back,
				{ desc = "Debug: Step Back in Time" }
			)

			for _, adapter in pairs({
				"pwa-node",
				"pwa-chrome",
				"pwa-msedge",
				"node-terminal",
				"pwa-extensionHost",
			}) do
				require("dap").adapters[adapter] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "node",
						args = {
							get_pkg_path(
								"js-debug-adapter",
								"/js-debug/src/dapDebugServer.js"
							),
							"${port}",
						},
					},
				}
			end

			for _, language in ipairs({ "typescript", "javascript" }) do
				require("dap").configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Debug Jest Tests",
						-- trace = true, -- include debugger info
						runtimeExecutable = "node",
						runtimeArgs = {
							"./node_modules/jest/bin/jest.js",
							"--runInBand",
						},
						rootPath = "${workspaceFolder}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						internalConsoleOptions = "neverOpen",
					},
					{
						type = "pwa-chrome",
						name = "Attach - Remote Debugging",
						request = "attach",
						program = "${file}",
						sourceMaps = true,
						protocol = "inspector",
						address = "localhost",
						port = 9222, -- Start Chrome google-chrome --remote-debugging-port=9222
						cwd = "${workspaceFolder}",
						webRoot = "${workspaceFolder}",
					},
					{
						type = "pwa-chrome",
						name = "Launch Chrome",
						request = "launch",
						url = "http://localhost:5001", -- This is for Vite. Change it to the framework you use
						webRoot = "${workspaceFolder}",
						userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
					},
					{
						type = "pwa-node",
						request = "launch",
						cwd = "${workspaceFolder}",
						webRoot = "${workspaceFolder}/src",
						sourceMaps = true,
						sourceMapPathOverrides = {
							"${workspaceFolder}/**",
							"!**/node_modules/**",
							"**/node_modules/.vite-temp/**",
							["webpack:///./src/*"] = "${workspaceFolder}/src/*",
							["vite://./src/*"] = "${workspaceFolder}/src/*",
							["/src/*"] = "${workspaceFolder}/src/*",
							-- This covers the internal Vite client
							["/@vite/client"] = "${workspaceFolder}/node_modules/vite/dist/client/client.mjs",
						},
						name = "Debug Vite Dev Server (Node)",
						runtimeExecutable = "node",
						runtimeArgs = {
							"--inspect-brk", -- Важно: замирает на старте, пока отладчик не подключится
							"./node_modules/vite/bin/vite.js",
							"--no-open", -- Предотвращает открытие лишних окон браузера сервером
							"--host",
						},
					},
				}
			end

			for _, language in ipairs({ "typescriptreact", "javascriptreact" }) do
				require("dap").configurations[language] = {
					{
						type = "pwa-chrome",
						name = "Attach - Remote Debugging",
						request = "attach",
						program = "${file}",
						cwd = vim.fn.getcwd(),
						sourceMaps = true,
						protocol = "inspector",
						port = 9222, -- Start Chrome google-chrome --remote-debugging-port=9222
						webRoot = "${workspaceFolder}",
					},
					{
						type = "pwa-chrome",
						name = "Launch Chrome",
						request = "launch",
						url = "http://localhost:5001", -- This is for Vite. Change it to the framework you use
						webRoot = "${workspaceFolder}",
						userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
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
				sections = {
					"watches",
					"scopes",
					"exceptions",
					"breakpoints",
					"threads",
					"repl",
					"console",
				},
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
				dap.defaults.python.exception_breakpoints = { "raised" } -- raised
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

			-- 1. RE-ATTACH LOGIC
			-----------------------------------------------------------------------
			local auto_reattach_enabled = true

			local function check_port_and_attach(config, retries)
				local host = config.host
					or (config.connect and config.connect.host)
					or "127.0.0.1"
				local port = config.port
					or (config.connect and config.connect.port)
					or 5678
				local max_retries = 30
				retries = retries or 0

				if retries > max_retries then
					vim.notify(
						"DAP: Re-attach timed out. Is the server running?",
						vim.log.levels.ERROR
					)
					return
				end

				local client = vim.loop.new_tcp()
				client:connect(host, port, function(err)
					client:close()
					if not err then
						vim.schedule(function()
							vim.notify(
								"DAP: Server found on "
									.. port
									.. "! Attaching...",
								vim.log.levels.INFO
							)
							dap.run(config)
						end)
					else
						-- Wait 1s and try again
						vim.defer_fn(function()
							check_port_and_attach(config, retries + 1)
						end, 1000)
					end
				end)
			end

			-- Command to manually stop debugging without it auto-starting again
			local function safe_detach()
				local session = dap.session()
				if session then
					auto_reattach_enabled = false -- Tell the listener "Don't wake up"
					dap.disconnect({ terminateDebuggee = false })
					vim.notify(
						"DAP: Manually detached. Auto-reload suspended.",
						vim.log.levels.WARN
					)
				end
			end

			-- Keymaps for the new logic
			vim.keymap.set(
				"n",
				"<leader>dd",
				safe_detach,
				{ desc = "Debug: Safe Detach (No Re-attach)" }
			)

			-- 2. LISTENERS
			-----------------------------------------------------------------------

			-- When a session starts, we always reset the flag so that unexpected
			-- terminations in the future trigger a re-attach.
			dap.listeners.after.event_initialized["debugpy_reflex_auto"] = function()
				auto_reattach_enabled = true
			end

			dap.listeners.after.event_terminated["debugpy_reflex_auto"] = function(
				session
			)
				if
					auto_reattach_enabled
					and session
					and session.config
					and session.config.request == "attach"
				then
					-- The session ended but NOT via safe_detach.
					-- Likely a Reflex restart or a crash.
					check_port_and_attach(session.config)
				else
					-- We reached here because of safe_detach OR it wasn't an 'attach' session.
					-- Reset the flag so the NEXT manual start behaves normally.
					auto_reattach_enabled = true
				end
			end

			-- 3. CONFIGURATIONS
			-----------------------------------------------------------------------
			-- (Keep your existing table.insert and port loop here)
			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "module",
				console = "integratedTerminal",
				module = "src",
				cwd = "${workspaceFolder}",
			})

			local debug_ports = { 5681, 5682, 5683, 5684, 5685, 5686 }
			for _, port in ipairs(debug_ports) do
				local env_label =
					os.getenv(string.format("DAP_PORT_%d_LABEL", port))
				local display_name = env_label
						and string.format("Attach to %s (%d)", env_label, port)
					or string.format("Attach to Docker (Port %d)", port)

				table.insert(dap.configurations.python, {
					type = "python",
					request = "attach",
					name = display_name,
					connect = {
						host = "127.0.0.1",
						port = port,
					},
					pathMappings = {
						{
							localRoot = vim.fn.getcwd(),
							remoteRoot = "/workspace/packages/rtms-backend",
						},
					},
				})
			end
		end,
	},
}
