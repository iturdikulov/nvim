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
		enabled = not require("config.platform").is_windows,
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
				local script = vim.fs.joinpath(vim.fn.getcwd(), "packages", "rtms-backend", "curl.sh")
				if vim.fn.filereadable(script) == 1 then
					vim.cmd("silent !" .. vim.fn.fnameescape(script) .. " &")
				end
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

			local frontend_services = {
				{
					id = "ltms",
					label = "LTMS",
					compose_service = "ltms-frontend",
					package = "ltms-frontend",
					port = 6573,
				},
				{
					id = "rtms",
					label = "RTMS",
					compose_service = "rtms-frontend",
					package = "rtms-frontend",
					port = 5173,
				},
				{
					id = "qems",
					label = "QEMS",
					compose_service = "qems-frontend",
					package = "qems-frontend",
					port = 6173,
				},
				{
					id = "qdms",
					label = "QDMS",
					compose_service = "qdms-frontend",
					package = "qdms-frontend",
					port = 6273,
				},
			}

			local function find_frontend_project_root()
				for _, start in ipairs({
					vim.api.nvim_buf_get_name(0),
					vim.fn.getcwd(),
				}) do
					if start ~= "" then
						local directory = vim.fn.isdirectory(start) == 1
								and vim.fs.normalize(start)
							or vim.fs.dirname(vim.fs.normalize(start))

						while directory and directory ~= "" do
							if
								vim.fn.filereadable(directory .. "/docker-compose.yml") == 1
								and vim.fn.isdirectory(directory .. "/packages") == 1
							then
								return directory
							end

							local parent = vim.fs.dirname(directory)
							if parent == directory then
								break
							end
							directory = parent
						end
					end
				end
			end

			local function system_async(command, options, callback)
				vim.system(command, options, function(result)
					vim.schedule(function()
						callback(result)
					end)
				end)
			end

			local function edge_has_frontend_target(frontend, callback)
				system_async(
					{
						"curl",
						"--fail",
						"--silent",
						"--max-time",
						"2",
						"http://127.0.0.1:9222/json/list",
					},
					{ text = true },
					function(result)
						if result.code ~= 0 then
							callback(false)
							return
						end

						local ok, targets = pcall(vim.json.decode, result.stdout)
						if not ok or type(targets) ~= "table" then
							callback(false)
							return
						end

						local url_prefix = "http://localhost:" .. frontend.port .. "/"
						for _, target in ipairs(targets) do
							if
								type(target.url) == "string"
								and vim.startswith(target.url, url_prefix)
							then
								callback(true)
								return
							end
						end
						callback(false)
					end
				)
			end

			local function prepare_frontend(frontend)
				return coroutine.create(function(dap_run_co)
					local finished = false
					local function finish(result, message)
						if finished then
							return
						end
						finished = true
						if message then
							vim.notify(message, vim.log.levels.ERROR)
						end
						coroutine.resume(dap_run_co, result)
					end

					local project_root = find_frontend_project_root()
					if not project_root then
						finish(dap.ABORT, frontend.label .. ": az-containers root was not found.")
						return
					end

					local function wait_for_target(attempt)
						edge_has_frontend_target(frontend, function(ready)
							if ready then
								finish(true)
							elseif attempt >= 60 then
								finish(
									dap.ABORT,
									frontend.label
										.. ": Edge tab on port 9222 did not become ready."
								)
							else
								vim.defer_fn(function()
									wait_for_target(attempt + 1)
								end, 500)
							end
						end)
					end

					local function ensure_edge()
						edge_has_frontend_target(frontend, function(ready)
							if ready then
								finish(true)
								return
							end

							local edge = vim.fn.exepath("microsoft-edge-stable")
							if edge == "" then
								edge = vim.fn.exepath("microsoft-edge")
							end
							if vim.fn.executable(edge) ~= 1 then
								finish(
									dap.ABORT,
									frontend.label .. ": Microsoft Edge was not found."
								)
								return
							end

							local job_id = vim.fn.jobstart({
								edge,
								"--remote-debugging-port=9222",
								"--user-data-dir="
									.. vim.fs.joinpath(vim.fn.stdpath("state"), "microsoft-edge-ltms-debug"),
								"--no-first-run",
								"--no-default-browser-check",
								"--new-window",
								"http://localhost:" .. frontend.port,
							}, { detach = true })
							if job_id <= 0 then
								finish(
									dap.ABORT,
									frontend.label .. ": failed to start Microsoft Edge."
								)
								return
							end
							wait_for_target(1)
						end)
					end

					local function wait_for_vite(attempt)
						system_async(
							{
								"curl",
								"--fail",
								"--silent",
								"--output",
								"/dev/null",
								"--max-time",
								"2",
								"http://127.0.0.1:" .. frontend.port,
							},
							{ text = true },
							function(result)
								if result.code == 0 then
									ensure_edge()
								elseif attempt >= 120 then
									finish(
										dap.ABORT,
										frontend.label
											.. ": Vite on port "
											.. frontend.port
											.. " did not become ready."
									)
								else
									vim.defer_fn(function()
										wait_for_vite(attempt + 1)
									end, 500)
								end
							end
						)
					end

					system_async(
						{
							project_root .. "/az",
							"up",
							"--no-deps",
							frontend.compose_service,
						},
						{ cwd = project_root, text = true, timeout = 120000 },
						function(result)
							if result.code ~= 0 then
								local detail = vim.trim(result.stderr or "")
								finish(
									dap.ABORT,
									frontend.label .. ": failed to start frontend Compose service"
										.. (detail ~= "" and (": " .. detail) or ".")
								)
								return
							end
							wait_for_vite(1)
						end
					)
				end)
			end

			local function make_edge_attach(frontend)
				return {
					type = "pwa-msedge",
					name = "Attach to " .. frontend.label .. " frontend (Edge)",
					frontend_service = frontend.id,
					request = "attach",
					address = "127.0.0.1",
					port = 9222,
					urlFilter = "http://localhost:" .. frontend.port .. "/*",
					webRoot = function()
						local root = find_frontend_project_root()
						return root and (root .. "/packages/" .. frontend.package) or dap.ABORT
					end,
					sourceMaps = true,
					sourceMapPathOverrides = function()
						local root = find_frontend_project_root()
						if not root then
							return dap.ABORT
						end
						local web_root = root .. "/packages/" .. frontend.package
						local container_root = "/apps/" .. frontend.package
						return {
							[container_root .. "/*"] = web_root .. "/*",
							["file://" .. container_root .. "/*"] = web_root .. "/*",
							["vite://./*"] = web_root .. "/*",
							["webpack:///./*"] = web_root .. "/*",
						}
					end,
					__frontendReady = function()
						return prepare_frontend(frontend)
					end,
				}
			end

			local edge_attach_configs = {}
			for _, frontend in ipairs(frontend_services) do
				table.insert(edge_attach_configs, make_edge_attach(frontend))
			end

			for _, language in ipairs({ "typescript", "javascript" }) do
				local configurations = vim.deepcopy(edge_attach_configs)
				vim.list_extend(configurations, {
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
				})
				require("dap").configurations[language] = configurations
			end

			for _, language in ipairs({ "typescriptreact", "javascriptreact", "vue" }) do
				require("dap").configurations[language] = vim.deepcopy(edge_attach_configs)
			end

			local function debug_project()
				local package = vim.fs.normalize(vim.fn.getcwd()):match("/packages/([^/]+)")
				return package
					and (package:match("^([%w_]+)%-frontend$") or package:match("^([%w_]+)%-backend$"))
			end

			local global_config_provider = dap.providers.configs["dap.global"]
			dap.providers.configs["dap.global"] = function(bufnr)
				local configurations = global_config_provider(bufnr)
				local project = debug_project()
				if not project then
					return configurations
				end

				return vim.tbl_filter(function(configuration)
					local configuration_project = configuration.frontend_service
						or configuration.backend_service
					return not configuration_project or configuration_project == project
				end, configurations)
			end
		end,
	},

	{
		"igorlfs/nvim-dap-view",
		enabled = not require("config.platform").is_windows,
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

			local backend_services = {
				{
					id = "ltms",
					label = "LTMS",
					compose_service = "ltms-backend",
					package = "ltms-backend",
					port = 61000,
					live_reload_env = "LTMS_LIVE_RELOAD",
				},
				{
					id = "rtms",
					label = "RTMS",
					compose_service = "rtms-backend",
					package = "rtms-backend",
					port = 61010,
					live_reload_env = "RTMS_LIVE_RELOAD",
				},
				{
					id = "qems",
					label = "QEMS",
					compose_service = "qems-backend",
					package = "qems-backend",
					port = 61020,
					live_reload_env = "QEMS_LIVE_RELOAD",
				},
				{
					id = "qdms",
					label = "QDMS",
					compose_service = "qdms-backend",
					package = "qdms-backend",
					port = 61030,
					live_reload_env = "QDMS_LIVE_RELOAD",
				},
				{
					id = "catalogs",
					label = "catalogs",
					compose_service = "catalogs",
					package = "catalogs-backend",
					port = 61040,
					live_reload_env = "CATALOGS_LIVE_RELOAD",
				},
				{
					id = "sso",
					label = "SSO",
					compose_service = "sso",
					package = "sso-backend",
					port = 61050,
					live_reload_env = "SSO_LIVE_RELOAD",
				},
			}

			local services_by_id = {}
			for _, service in ipairs(backend_services) do
				services_by_id[service.id] = service
			end

			local exiting = false
			local active_profile_id
			local suppressed_sessions = setmetatable({}, { __mode = "k" })

			local function is_backend_attach(config)
				return config
					and config.request == "attach"
					and type(config.backend_service) == "string"
					and services_by_id[config.backend_service] ~= nil
			end

			local function find_backend_project_root()
				for _, start in ipairs({
					vim.api.nvim_buf_get_name(0),
					vim.fn.getcwd(),
				}) do
					if start ~= "" then
						local directory = vim.fn.isdirectory(start) == 1
								and vim.fs.normalize(start)
							or vim.fs.dirname(vim.fs.normalize(start))

						while directory and directory ~= "" do
							if
								vim.fn.filereadable(directory .. "/docker-compose.yml") == 1
								and vim.fn.isdirectory(directory .. "/packages") == 1
							then
								return directory
							end

							local parent = vim.fs.dirname(directory)
							if parent == directory then
								break
							end
							directory = parent
						end
					end
				end
			end

			local function system_async(command, options, callback)
				vim.system(command, options, function(result)
					vim.schedule(function()
						callback(result)
					end)
				end)
			end

			local function watch_paths(project_root, _service)
				-- Один watch на compose-проект; state общий с ./az.
				local state_dir = project_root .. "/runtime/compose-watch"
				vim.fn.mkdir(state_dir, "p")
				return {
					lock = state_dir .. "/project.lock",
					pid = state_dir .. "/project.pid",
					log = state_dir .. "/project.log",
					legacy_done = state_dir .. "/project.legacy-cleaned",
				}
			end

			local function read_watch_pid(path)
				if vim.fn.filereadable(path) ~= 1 then
					return nil
				end
				local lines = vim.fn.readfile(path)
				return tonumber(lines[1])
			end

			local function process_matches_watch(pid, project_root, _service)
				if not pid or vim.uv.kill(pid, 0) ~= 0 then
					return false
				end
				local cwd = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
				if not cwd or vim.fs.normalize(cwd) ~= project_root then
					return false
				end
				local ok, lines = pcall(
					vim.fn.readfile,
					"/proc/" .. pid .. "/cmdline",
					"b"
				)
				if not ok then
					return false
				end
				local command = table.concat(lines, " "):gsub("%z", " ")
				return command:find("docker", 1, true)
					and command:find("compose", 1, true)
					and command:find("watch", 1, true)
			end

			local function find_watch_pid(project_root, service, paths)
				local pid = read_watch_pid(paths.pid)
				if process_matches_watch(pid, project_root, service) then
					return pid
				end
				local result = vim.system({ "ps", "-eo", "pid=" }, { text = true }):wait()
				if result.code ~= 0 then
					return nil
				end
				for pid_text in (result.stdout or ""):gmatch("%d+") do
					local candidate = tonumber(pid_text)
					if process_matches_watch(candidate, project_root, service) then
						return candidate
					end
				end
				return nil
			end

			local function cleanup_legacy_ltms_watch(project_root, service, paths, done)
				if service.id ~= "ltms" or vim.fn.filereadable(paths.legacy_done) == 1 then
					done()
					return
				end
				system_async({ "ps", "-eo", "pid=" }, { text = true }, function(result)
					if result.code == 0 then
						local shared_pid = read_watch_pid(paths.pid)
						for pid_text in (result.stdout or ""):gmatch("%d+") do
							local pid = tonumber(pid_text)
							-- Не убиваем единственный project watch из ./az / shared pid.
							if pid ~= shared_pid
								and process_matches_watch(pid, project_root, service)
							then
								-- Старые per-service watch с именем сервиса в cmdline.
								local ok, lines = pcall(
									vim.fn.readfile,
									"/proc/" .. pid .. "/cmdline",
									"b"
								)
								local command = ok
										and table.concat(lines, " "):gsub("%z", " ")
									or ""
								if command:find("ltms%-backend", 1)
									or command:find("ltms_backend", 1, true)
								then
									vim.uv.kill(pid, 15)
								end
							end
						end
					end
					vim.fn.writefile({ "legacy LTMS watcher cleanup completed" }, paths.legacy_done)
					done()
				end)
			end

			local function ensure_watch(project_root, service, callback)
				local paths = watch_paths(project_root, service)
				cleanup_legacy_ltms_watch(project_root, service, paths, function()
					local pid = find_watch_pid(project_root, service, paths)
					if pid then
						vim.fn.writefile({ tostring(pid) }, paths.pid)
						callback(true)
						return
					end
					vim.fn.delete(paths.pid)

					-- Без SERVICE: watch всех develop.watch (backend + frontend).
					local watch_script = [[
set -u
exec 9>>"$1"
flock -n 9 || exit 0
printf '%s\n' "$$" >"$2"
exec docker compose watch --quiet --no-up >>"$3" 2>&1
]]
					local job_id = vim.fn.jobstart({
						"/bin/sh",
						"-c",
						watch_script,
						"nvim-compose-watch",
						paths.lock,
						paths.pid,
						paths.log,
					}, { cwd = project_root, detach = true })
					if job_id <= 0 then
						vim.notify(
							"Compose Watch: failed to launch. See " .. paths.log,
							vim.log.levels.ERROR
						)
						callback(false)
						return
					end
					vim.notify("Compose Watch: starting project watcher...", vim.log.levels.INFO)
					callback(true)
				end)
			end

			local function stop_watch(project_root, service, callback)
				local paths = watch_paths(project_root, service)
				local pid = find_watch_pid(project_root, service, paths)
				if not pid then
					vim.fn.delete(paths.pid)
					callback(true)
					return
				end
				vim.uv.kill(pid, 15)
				vim.fn.delete(paths.pid)
				callback(true)
			end

			local function get_live_reload(project_root, service, callback)
				system_async(
					{ "docker", "compose", "config", "--environment" },
					{ cwd = project_root, text = true },
					function(result)
						if result.code ~= 0 then
							vim.notify(service.label .. ": docker compose config failed.", vim.log.levels.ERROR)
							callback(nil)
							return
						end
						local value
						for line in (result.stdout or ""):gmatch("[^\r\n]+") do
							local name, candidate = line:match("^([^=]+)=(.*)$")
							if name == service.live_reload_env then
								value = candidate
								break
							end
						end
						value = value or "1"
						if value ~= "0" and value ~= "1" then
							vim.notify(
								service.live_reload_env .. " must be 0 or 1, got: " .. value,
								vim.log.levels.ERROR
							)
							callback(nil)
							return
						end
						callback(value == "1")
					end
				)
			end

			local function compose_up(project_root, service, callback)
				system_async(
					{ project_root .. "/az", service.compose_service },
					{ cwd = project_root, text = true, timeout = 900000 },
					function(result)
						if result.code ~= 0 then
							local detail = vim.trim(result.stderr or "")
							vim.notify(
								service.label .. ": failed to build or start debug service"
									.. (detail ~= "" and (": " .. detail) or "."),
								vim.log.levels.ERROR
							)
							callback(false)
							return
						end
						callback(true)
					end
				)
			end

			local function wait_for_debugpy(project_root, service, port, callback, attempt)
				attempt = attempt or 0
				local port_hex = string.format("%04X", port)
				local awk_program = string.format(
					'$2 ~ /:%s$/ && $4 == "0A" { found = 1 } END { exit !found }',
					port_hex
				)
				system_async({
					"docker",
					"compose",
					"exec",
					"-T",
					service.compose_service,
					"awk",
					awk_program,
					"/proc/net/tcp",
					"/proc/net/tcp6",
				}, { cwd = project_root, text = true }, function(result)
					if result.code == 0 then
						callback(true)
						return
					end
					if attempt >= 240 then
						vim.notify(
							service.label .. ": debugpy on port " .. port .. " did not become ready.",
							vim.log.levels.ERROR
						)
						callback(false)
						return
					end
					vim.defer_fn(function()
						wait_for_debugpy(project_root, service, port, callback, attempt + 1)
					end, 500)
				end)
			end

			local function prepare_backend_attach(config, callback)
				local service = services_by_id[config.backend_service]
				local project_root = find_backend_project_root()
				if not project_root then
					vim.notify("DAP: az-containers root was not found.", vim.log.levels.ERROR)
					callback(false)
					return
				end
				get_live_reload(project_root, service, function(live_reload)
					if live_reload == nil then
						callback(false)
						return
					end
					compose_up(project_root, service, function(started)
						if not started then
							callback(false)
							return
						end
						-- Project-wide watch; LIVE_RELOAD=0 только отключает USR1 в контейнере,
						-- сам watch не останавливаем (нужен другим сервисам / frontend).
						if not live_reload then
							wait_for_debugpy(project_root, service, config.connect.port, callback)
							return
						end
						ensure_watch(project_root, service, function(watch_ok)
							if not watch_ok then
								callback(false)
								return
							end
							wait_for_debugpy(project_root, service, config.connect.port, callback)
						end)
					end)
				end)
			end

			local function safe_detach()
				local session = dap.session()
				if session then
					suppressed_sessions[session] = true
					dap.disconnect({ terminateDebuggee = false })
					vim.notify("DAP: manually detached; auto-reattach is suspended.", vim.log.levels.WARN)
				end
			end

			vim.keymap.set("n", "<leader>dd", safe_detach, {
				desc = "Debug: Safe Detach (No Re-attach)",
			})

			vim.api.nvim_create_autocmd("ExitPre", {
				group = "DapGroup",
				callback = function()
					exiting = true
				end,
			})

			local function suppress_intentional_close(session)
				if is_backend_attach(session and session.config) then
					suppressed_sessions[session] = true
				end
			end

			dap.listeners.before.disconnect["backend_auto_reattach"] =
				suppress_intentional_close
			dap.listeners.before.terminate["backend_auto_reattach"] =
				suppress_intentional_close

			dap.listeners.after.event_initialized["backend_auto_reattach"] = function(session)
				if not is_backend_attach(session and session.config) then
					return
				end
				local config = vim.deepcopy(session.config)
				local filetype = session.filetype
				active_profile_id = config.backend_profile
				session.on_close["backend_compose_watch_auto_reattach"] = function()
					if exiting
						or suppressed_sessions[session]
						or active_profile_id ~= config.backend_profile
					then
						return
					end
					local project_root = find_backend_project_root()
					local service = services_by_id[config.backend_service]
					if not project_root then
						return
					end
					get_live_reload(project_root, service, function(live_reload)
						if live_reload and active_profile_id == config.backend_profile then
							dap.run(config, { filetype = filetype, new = true })
						elseif live_reload == false then
							stop_watch(project_root, service, function() end)
						end
					end)
				end
			end

			local python_adapter = dap.adapters.python
			dap.adapters.python = function(callback, config, parent_session)
				if not is_backend_attach(config) then
					python_adapter(callback, config, parent_session)
					return
				end
				active_profile_id = config.backend_profile
				python_adapter(function(adapter)
					adapter.options = vim.tbl_extend(
						"force",
						adapter.options or {},
						{ max_retries = 480 }
					)
					local original_enrich_config = adapter.enrich_config
					adapter.enrich_config = function(configuration, on_config)
						prepare_backend_attach(configuration, function(ready)
							if not ready then
								return
							end
							if original_enrich_config then
								original_enrich_config(configuration, on_config)
							else
								on_config(configuration)
							end
						end)
					end
					callback(adapter)
				end, config, parent_session)
			end
			dap.adapters.debugpy = dap.adapters.python

			table.insert(dap.configurations.python, {
				type = "python",
				request = "launch",
				name = "module",
				console = "integratedTerminal",
				module = "src",
				cwd = "${workspaceFolder}",
			})

			local backend_configurations = {}
			for _, service in ipairs(backend_services) do
				for offset, process_name in ipairs({ "backend", "Celery" }) do
					local port = service.port + offset - 1
					local profile_id = service.id .. ":" .. process_name:lower()
					table.insert(backend_configurations, {
						type = "python",
						request = "attach",
						name = "Attach to " .. service.label .. " " .. process_name,
						backend_service = service.id,
						backend_profile = profile_id,
						redirectOutput = true,
						connect = {
							host = "127.0.0.1",
							port = port,
						},
						pathMappings = function()
							local project_root = find_backend_project_root()
							if not project_root then
								return dap.ABORT
							end
							return {
								{
									localRoot = project_root .. "/packages/" .. service.package,
									remoteRoot = "/apps/" .. service.package,
								},
							}
						end,
					})
				end
			end
			dap.configurations.python = vim.list_extend(
				backend_configurations,
				dap.configurations.python
			)
		end,
	},
}
