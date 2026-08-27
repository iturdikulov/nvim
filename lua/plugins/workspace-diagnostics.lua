local container_workspace = require("config.container_workspace")

local SKIP_CLIENTS = {
	copilot = true,
	pylsp = true,
}

--- vue_ls + vtsls на одном .vue → двойной didOpen через devcontainer.
--- @param clients vim.lsp.Client[]
--- @return vim.lsp.Client[]
local function filter_workspace_clients(clients)
	local has_vtsls = false
	for _, client in ipairs(clients) do
		if client.name == "vtsls" then
			has_vtsls = true
			break
		end
	end
	return vim.tbl_filter(function(client)
		if SKIP_CLIENTS[client.name] then
			return false
		end
		if has_vtsls and client.name == "vue_ls" then
			return false
		end
		return true
	end, clients)
end

local TROUBLE_OPTS = {
	mode = "diagnostics",
	new = true,
	open_no_results = true,
	focus = true,
}

local detected_filetypes = {}
local dont_cache_extensions = { conf = true }

local eslint_root_markers = {
	"eslint.config.mjs",
	"eslint.config.js",
	"eslint.config.cjs",
	".eslintrc.cjs",
	".eslintrc.js",
	".eslintrc.json",
}

--- @param dir string|nil
--- @return string?
local function git_root_from(dir)
	if not dir or dir == "" then
		return nil
	end
	return vim.fs.root(dir, ".git")
end

--- @param bufnr integer
--- @return string?
local function git_root(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name ~= "" then
		local root = git_root_from(name)
		if root then
			return root
		end
	end
	return git_root_from(vim.fn.getcwd())
end

--- @param path string
--- @return string?
local function detect_filetype(path)
	path = vim.fs.normalize(path)
	local ext = vim.fn.fnamemodify(path, ":e")
	if ext ~= "" and detected_filetypes[ext] ~= nil then
		local cached = detected_filetypes[ext]
		return cached ~= false and cached or nil
	end

	local filetype = vim.filetype.match({ filename = path })
	if not filetype then
		for _, buf in ipairs(vim.fn.getbufinfo()) do
			if vim.fs.normalize(buf.name) == path then
				filetype = vim.filetype.match({ buf = buf.bufnr })
				break
			end
		end
	end
	if not filetype then
		local temp = vim.fn.bufadd(path)
		vim.fn.bufload(temp)
		filetype = vim.filetype.match({ buf = temp })
		vim.api.nvim_buf_delete(temp, { force = true })
	end

	if ext ~= "" and not dont_cache_extensions[ext] then
		detected_filetypes[ext] = filetype or false
	end
	return filetype
end

--- @param git_root_dir string
--- @param scope_root string
--- @return string[]
local function list_git_files(git_root_dir, scope_root)
	git_root_dir = vim.fs.normalize(git_root_dir)
	scope_root = vim.fs.normalize(scope_root)

	local rel_files = vim.fn.systemlist({ "git", "-C", git_root_dir, "ls-files" })
	if vim.v.shell_error ~= 0 then
		return {}
	end

	local files = {}
	for _, rel in ipairs(rel_files) do
		if rel ~= "" then
			local abs = vim.fs.normalize(vim.fs.joinpath(git_root_dir, rel))
			if (abs == scope_root or vim.startswith(abs, scope_root .. "/"))
				and vim.fn.filereadable(abs) == 1
			then
				files[#files + 1] = abs
			end
		end
	end
	return files
end

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @return string[]
local function files_for_client(client, bufnr)
	local root = git_root(bufnr)
	if not root or not client.config.root_dir then
		return {}
	end
	return list_git_files(root, vim.fs.normalize(client.config.root_dir))
end

local function ensure_trouble_ready()
	require("trouble")
end

--- @return integer
local function diagnostic_count()
	return #vim.diagnostic.get(nil)
end

--- @return integer
local function diagnostic_file_count()
	local seen = {}
	for _, diag in ipairs(vim.diagnostic.get(nil)) do
		local name = vim.api.nvim_buf_get_name(diag.bufnr)
		if name ~= "" then
			seen[name] = true
		end
	end
	return vim.tbl_count(seen)
end

--- @param workspace string
--- @param host_path string
--- @return string
local function to_container_path(workspace, host_path)
	local remote = "/workspace"
	local ok, cache = pcall(require, "devcontainers.cache")
	if ok then
		local entry = cache.check(workspace)
		if entry and entry.remote_dir then
			remote = entry.remote_dir
		end
	end
	host_path = vim.fs.normalize(host_path)
	if vim.startswith(host_path, workspace) then
		return remote .. host_path:sub(#workspace + 1)
	end
	return host_path
end

--- @param workspace string
--- @param container_path string
--- @return string
local function container_path_to_host(workspace, container_path)
	local remote = "/workspace"
	local ok, cache = pcall(require, "devcontainers.cache")
	if ok then
		local entry = cache.check(workspace)
		if entry and entry.remote_dir then
			remote = entry.remote_dir
		end
	end
	container_path = vim.fs.normalize(container_path)
	workspace = vim.fs.normalize(workspace)
	if vim.startswith(container_path, remote) then
		return workspace .. container_path:sub(#remote + 1)
	end
	return container_path
end

local ESLINT_FT = {
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
	vue = true,
}

--- @param output string
--- @return table<string, vim.Diagnostic[]>
local function parse_eslint_batch(output)
	local severities = {
		vim.diagnostic.severity.WARN,
		vim.diagnostic.severity.ERROR,
	}
	local trimmed = vim.trim(output or "")
	if trimmed == "" or trimmed:find("No ESLint configuration found") then
		return {}
	end
	local ok, data = pcall(vim.json.decode, output, { luanil = { object = true, array = true } })
	if not ok then
		return {}
	end
	local by_file = {}
	for _, result in ipairs(data or {}) do
		local path = result.filePath
		if path then
			local diags = {}
			for _, msg in ipairs(result.messages or {}) do
				diags[#diags + 1] = {
					lnum = msg.line and (msg.line - 1) or 0,
					end_lnum = msg.endLine and (msg.endLine - 1) or nil,
					col = msg.column and (msg.column - 1) or 0,
					end_col = msg.endColumn and (msg.endColumn - 1) or nil,
					message = msg.message,
					code = msg.ruleId,
					severity = severities[msg.severity],
					source = "eslint_d",
				}
			end
			by_file[vim.fs.normalize(path)] = diags
		end
	end
	return by_file
end

--- Один eslint_d на весь пакет в devcontainer (~2 с вместо сотен exec).
--- @param context_bufnr integer
--- @param bufnrs integer[]
--- @return boolean ran
local function lint_buffers_batch_container(context_bufnr, bufnrs)
	local ok_lint, lint = pcall(require, "lint")
	if not ok_lint then
		return false
	end

	local package_root = vim.fs.root(context_bufnr, eslint_root_markers)
	local workspace = container_workspace.workspace_root(context_bufnr)
	if not package_root or not workspace then
		return false
	end
	package_root = vim.fs.normalize(package_root)
	workspace = vim.fs.normalize(workspace)

	if container_workspace.container_kind(package_root) ~= "frontend" then
		return false
	end

	local ok_cli, cli = pcall(require, "devcontainers.cli")
	if not ok_cli or not cli.container_is_running(package_root) then
		return false
	end

	local rel_files = {}
	local seen = {}
	for _, b in ipairs(bufnrs) do
		if ESLINT_FT[vim.bo[b].filetype] then
			local host = vim.fs.normalize(vim.api.nvim_buf_get_name(b))
			if host ~= "" and vim.startswith(host, package_root .. "/") and not seen[host] then
				seen[host] = true
				rel_files[#rel_files + 1] = host:sub(#package_root + 2)
			end
		end
	end
	if #rel_files == 0 then
		return false
	end

	local container_pkg = to_container_path(workspace, package_root)
	local cmdline = table.concat(vim.tbl_map(vim.fn.shellescape, rel_files), " ")
	local shell = string.format(
		"cd %s && eslint_d --format json --cache %s",
		vim.fn.shellescape(container_pkg),
		cmdline
	)
	local cmd = cli.cmd(package_root, "exec", "sh", "-c", shell)
	local result = vim.system(cmd, { timeout = 120000 }):wait()
	if result.code ~= 0 and vim.trim(result.stdout or "") == "" then
		return false
	end

	local by_file = parse_eslint_batch(result.stdout or "")
	local ns = lint.get_namespace("eslint_d")
	for container_path, diags in pairs(by_file) do
		local host = container_path_to_host(workspace, container_path)
		local file_bufnr = vim.fn.bufadd(host)
		vim.fn.bufload(file_bufnr)
		vim.bo[file_bufnr].bufhidden = "hide"
		vim.diagnostic.set(ns, file_bufnr, diags)
	end
	return true
end

--- @param linter lint.Linter
--- @return lint.Linter
local function wrap_eslint_d_for_container(linter)
	if linter.name ~= "eslint_d" then
		return linter
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local package_root = vim.fs.root(bufnr, eslint_root_markers)
	if package_root then
		linter.cwd = package_root
	end

	local workspace = container_workspace.workspace_root(bufnr)
	if not workspace or not package_root then
		return linter
	end
	workspace = vim.fs.normalize(workspace)
	package_root = vim.fs.normalize(package_root)

	if container_workspace.container_kind(package_root) ~= "frontend" then
		return linter
	end

	local ok_cli, cli = pcall(require, "devcontainers.cli")
	if not ok_cli or not cli.container_is_running(package_root) then
		return linter
	end

	local host_fname = vim.api.nvim_buf_get_name(bufnr)
	local container_fname = to_container_path(workspace, host_fname)
	local container_pkg = to_container_path(workspace, package_root)
	local shell = string.format(
		"cd %s && exec eslint_d --format json --stdin --stdin-filename %s",
		vim.fn.shellescape(container_pkg),
		vim.fn.shellescape(container_fname)
	)
	local prefix = cli.cmd(package_root, "exec", "sh", "-c", shell)
	linter.cmd = prefix[1]
	linter.args = vim.list_slice(prefix, 2)
	return linter
end

--- @param bufnrs integer[]
--- @param opts? { via_container?: boolean, context_bufnr?: integer }
local function lint_buffers(bufnrs, opts)
	opts = opts or {}
	if opts.via_container and opts.context_bufnr then
		lint_buffers_batch_container(opts.context_bufnr, bufnrs)
		return
	end

	local ok, lint = pcall(require, "lint")
	if not ok then
		return
	end

	for _, bufnr in ipairs(bufnrs) do
		vim.schedule(function()
			vim.api.nvim_buf_call(bufnr, function()
				if lint.linters_by_ft[vim.bo.filetype] then
					lint.try_lint(nil, {
						wrap_linter = wrap_eslint_d_for_container,
						ignore_errors = true,
					})
				end
			end)
		end)
	end
end

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param on_done fun(opened: integer, attached: integer[])
local function attach_client_files(client, bufnr, on_done)
	if not client.config.filetypes then
		vim.notify(
			("Workspace diagnostics: %s пропущен (нет config.filetypes)"):format(client.name),
			vim.log.levels.WARN,
			{ title = "Workspace Diagnostics" }
		)
		on_done(0, {})
		return
	end

	local current = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
	local files = files_for_client(client, bufnr)
	local attached = {}
	local opened = 0
	local index = 1
	local batch_size = client.config._devcontainers and 12 or 16
	local batch_delay_ms = client.config._devcontainers and 25 or 0

	local function next_batch()
		local limit = math.min(index + batch_size - 1, #files)
		for i = index, limit do
			local path = files[i]
			if path ~= current then
				local filetype = detect_filetype(path)
				if filetype and vim.tbl_contains(client.config.filetypes, filetype) then
					opened = opened + 1
					local file_bufnr = vim.fn.bufadd(path)
					vim.fn.bufload(file_bufnr)
					vim.bo[file_bufnr].bufhidden = "hide"
					if not vim.lsp.buf_is_attached(file_bufnr, client.id) then
						vim.lsp.buf_attach_client(file_bufnr, client.id)
					end
					attached[#attached + 1] = file_bufnr
				end
			end
		end

		index = limit + 1
		if index <= #files then
			vim.defer_fn(next_batch, batch_delay_ms)
			return
		end

		on_done(opened, attached)
	end

	next_batch()
end

--- @param timeout_ms integer
--- @param opts? { min_wait_ms?: integer, stable_polls?: integer }
--- @param on_done fun()
local function wait_for_diagnostics(timeout_ms, opts, on_done)
	if type(opts) == "function" then
		on_done = opts
		opts = {}
	end
	opts = opts or {}

	local poll_ms = 500
	local stable_polls = opts.stable_polls or 6
	local min_wait_ms = opts.min_wait_ms or 3000
	local started = vim.uv.now()
	local deadline = started + timeout_ms
	local last_count = diagnostic_count()
	local stable = 0

	local timer = vim.uv.new_timer()
	timer:start(poll_ms, poll_ms, function()
		vim.schedule(function()
			local now = vim.uv.now()
			local count = diagnostic_count()
			if count == last_count then
				stable = stable + 1
			else
				stable = 0
				last_count = count
			end

			local waited = now - started
			local ready = waited >= min_wait_ms and stable >= stable_polls
			if ready or now >= deadline then
				timer:stop()
				timer:close()
				on_done()
			end
		end)
	end)
end

local function open_trouble_diagnostics()
	require("trouble").open(TROUBLE_OPTS)
	require("trouble").refresh("diagnostics")
end

local function run_workspace_diagnostics()
	local bufnr = vim.api.nvim_get_current_buf()
	local root = git_root(bufnr)

	local clients = filter_workspace_clients(vim.lsp.get_clients({ bufnr = bufnr }))

	if #clients == 0 then
		vim.notify(
			"Нет LSP-клиентов на текущем буфере (copilot/pylsp пропускаются)",
			vim.log.levels.WARN,
			{ title = "Workspace Diagnostics" }
		)
		return
	end

	if not root then
		vim.notify(
			"Текущий проект не git-репозиторий — список файлов недоступен",
			vim.log.levels.ERROR,
			{ title = "Workspace Diagnostics" }
		)
		return
	end

	ensure_trouble_ready()

	local pending = #clients
	local total_files = 0
	local ran = {}
	local all_bufnrs = {}
	local has_container = false
	for _, client in ipairs(clients) do
		if client.config._devcontainers then
			has_container = true
			break
		end
	end

	vim.notify(
		"Сканирую workspace… Trouble откроется после стабилизации",
		vim.log.levels.INFO,
		{ title = "Workspace Diagnostics", timeout = 2500 }
	)

	local function finish_scan()
		local seen = {}
		local unique_bufnrs = {}
		for _, b in ipairs(all_bufnrs) do
			if not seen[b] then
				seen[b] = true
				unique_bufnrs[#unique_bufnrs + 1] = b
			end
		end
		lint_buffers(unique_bufnrs, { via_container = has_container, context_bufnr = bufnr })
		wait_for_diagnostics(90000, {
			min_wait_ms = has_container and 3000 or 4000,
			stable_polls = has_container and 5 or 6,
		}, function()
			local scope = vim.fs.normalize(clients[1].config.root_dir or root)
			local diags = diagnostic_count()
			local files = diagnostic_file_count()

			open_trouble_diagnostics()

			vim.notify(
				("Готово: %d диагностик в %d файлах. Сканировал %d файлов (%s) в %s"):format(
					diags,
					files,
					total_files,
					table.concat(ran, ", "),
					vim.fn.fnamemodify(scope, ":~:.")
				),
				diags > 0 and vim.log.levels.INFO or vim.log.levels.WARN,
				{ title = "Workspace Diagnostics", timeout = 8000 }
			)
		end)
	end

	for _, client in ipairs(clients) do
		if client:supports_method("workspace/diagnostic", bufnr) then
			vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
			ran[#ran + 1] = client.name .. " (native)"
			pending = pending - 1
			if pending == 0 then
				finish_scan()
			end
		elseif client:supports_method("textDocumentSync/openClose") then
			attach_client_files(client, bufnr, function(opened, attached)
				total_files = total_files + opened
				ran[#ran + 1] = client.name
				vim.list_extend(all_bufnrs, attached)
				pending = pending - 1
				if pending == 0 then
					finish_scan()
				end
			end)
		else
			pending = pending - 1
			if pending == 0 then
				finish_scan()
			end
		end
	end
end

return {
	"artemave/workspace-diagnostics.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"folke/trouble.nvim",
		"mfussenegger/nvim-lint",
	},
	cmd = "WorkspaceDiagnostics",
	keys = {
		{
			"<leader>xw",
			"<cmd>WorkspaceDiagnostics<cr>",
			desc = "Workspace diagnostics",
		},
	},
	config = function()
		vim.api.nvim_create_user_command("WorkspaceDiagnostics", run_workspace_diagnostics, {
			desc = "Populate LSP diagnostics for all project files",
		})
	end,
}
