--- LSP cmd: `*-frontend` → alpine, иначе → ltms-backend.
--- Path mapping всегда от корня monorepo (`az`), не от packages/*.
local M = {}

--- Сервер должен жить в matching-контейнере; иначе — local Mason.
local SERVER_KIND = {
	vtsls = "frontend",
	vue_ls = "frontend",
	bashls = "frontend",
	yamlls = "frontend",
	jsonls = "frontend",
	basedpyright = "backend",
	pylsp = "backend",
	ruff = "backend",
}

---@type table<string, { entry: table, package_root: string }>
local kind_entries = {}
---@type table<string, thread[]>
local kind_locks = {}

---@param kind string
---@param az string
---@return string
local function kind_key(kind, az)
	return az .. ":" .. kind
end

---@param az string
---@param package_root string
---@return string
local function container_package_dir(az, package_root)
	local remote = "/workspace"
	local ok, cache = pcall(require, "devcontainers.cache")
	if ok then
		local entry = cache.check(az)
		if entry and entry.remote_dir then
			remote = entry.remote_dir
		end
	end
	return remote .. package_root:sub(#vim.fs.normalize(az) + 1)
end

--- devcontainer exec стартует с cwd=workspaceFolder (/workspace), не packages/*.
---@param az string
---@param package_root string
---@param server_cmd string[]
---@return string[]
local function wrap_exec_in_package(az, package_root, server_cmd)
	local container_pkg = container_package_dir(az, package_root)
	local cmdline = table.concat(vim.tbl_map(vim.fn.shellescape, server_cmd), " ")
	return {
		"sh",
		"-c",
		string.format("cd %s && exec %s", vim.fn.shellescape(container_pkg), cmdline),
	}
end

---@param az string
---@param up table
---@param inspect table
---@param config_path string
local function inject_cache(az, up, inspect, config_path)
	local cache = require("devcontainers.cache")
	local cli = require("devcontainers.cli")
	local orig_read = cli.read_configuration
	cli.read_configuration = function(ws)
		if vim.fs.normalize(ws) == vim.fs.normalize(az) then
			return {
				workspace = {
					workspaceFolder = up.remoteWorkspaceFolder,
					workspaceMount = "",
				},
				configuration = {
					configFilePath = {
						path = config_path,
						fsPath = config_path,
						scheme = "file",
					},
				},
			}
		end
		return orig_read(ws)
	end
	local ok, err = pcall(function()
		cache.clear(az)
		cache.fetch(az, { up = up, inspect = inspect })
	end)
	cli.read_configuration = orig_read
	if not ok then
		error(err)
	end
end

---@async
---@param kind string
---@param az string
---@param package_root string
---@return table|false
local function ensure_kind(kind, az, package_root)
	assert(coroutine.running())

	local key = kind_key(kind, az)
	local cached = kind_entries[key]
	if cached then
		local docker = require("devcontainers.docker")
		local ok_inspect, inspect = pcall(docker.inspect, cached.entry.container_id)
		local running = ok_inspect
			and type(inspect) == "table"
			and inspect.State
			and inspect.State.Running
		if running then
			local cache = require("devcontainers.cache")
			local entry = cache.check(az)
			if not entry or entry.container_id ~= cached.entry.container_id then
				inject_cache(az, {
					outcome = "success",
					containerId = cached.entry.container_id,
					remoteUser = cached.entry.remote_user,
					remoteWorkspaceFolder = cached.entry.remote_dir,
				}, inspect, cached.entry.config_path)
			end
			return cached.entry
		end
		kind_entries[key] = nil
	end

	if kind_locks[key] then
		table.insert(kind_locks[key], coroutine.running())
		return coroutine.yield()
	end
	kind_locks[key] = {}

	local cli = require("devcontainers.cli")
	local docker = require("devcontainers.docker")
	local cw = require("config.container_workspace")

	local entry = false
	local ok, err = xpcall(function()
		local result = cli.devcontainer_up(package_root)
		if not result.ok or not result.status then
			error(result.error or "devcontainer up failed")
		end
		local up = result.status
		local inspect = docker.inspect(up.containerId)
		local config_path = cw.devcontainer_config(kind, az)
		inject_cache(az, up, inspect, config_path)
		entry = {
			workspace_dir = az,
			container_id = up.containerId,
			container_name = inspect.Name,
			remote_user = up.remoteUser,
			remote_dir = up.remoteWorkspaceFolder,
			config_path = config_path,
		}
		kind_entries[key] = { entry = entry, package_root = package_root }
	end, debug.traceback)

	local pending = kind_locks[key] or {}
	kind_locks[key] = nil
	for _, co in ipairs(pending) do
		coroutine.resume(co, ok and entry or false)
	end

	if not ok then
		error(err)
	end
	return entry
end

--- Override: любой path под az → --workspace-folder monorepo + --config by kind.
function M.setup_cli_override()
	local ok, cli = pcall(require, "devcontainers.cli")
	if not ok then
		return
	end
	local cw = require("config.container_workspace")
	local config = require("devcontainers.config")
	local utils = require("devcontainers.utils")

	pcall(cli.clear_cmd_override, "az-split")
	cli.register_cmd_override("az-split", function(workspace_dir, subcommand, ...)
		local az = cw.find_workspace_from_dir(workspace_dir)
		if not az or not cw.has_devcontainer_ancestor(az) then
			return nil
		end
		local kind = cw.container_kind(workspace_dir)
		local cfg = cw.devcontainer_config(kind, az)
		if not vim.uv.fs_stat(cfg) then
			return nil
		end
		return utils.flatten(
			config.devcontainers_cli_cmd,
			subcommand,
			"--workspace-folder",
			az,
			"--config",
			cfg,
			...
		)
	end, 100)
end

---@param cmd string[]|fun(config: vim.lsp.ClientConfig): string[]
---@param opts? { before_start?: fun(config: vim.lsp.ClientConfig), no_local_fallback?: boolean }
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers, config: vim.lsp.ClientConfig): vim.lsp.rpc.PublicClient
function M.lsp_cmd(cmd, opts)
	opts = opts or {}

	return function(dispatchers, client_config)
		local cw = require("config.container_workspace")
		local log = require("devcontainers.log")()
		local cli = require("devcontainers.cli")
		local paths = require("devcontainers.paths")
		local rpc = require("devcontainers.lsp.rpc")

		local function resolve_cmd()
			local used = cmd
			if vim.is_callable(used) then
				return used(client_config)
			end
			return used
		end

		local server_cmd = resolve_cmd()
		client_config._devcontainers = client_config._devcontainers or {}

		local function local_fallback(reason)
			if opts.no_local_fallback then
				error(reason)
			end
			log.warn(
				"falling back to local cmd: name=%s root=%s: %s",
				client_config.name,
				client_config.root_dir,
				reason
			)
			client_config._devcontainers.cmd = server_cmd
			return rpc.cmd_to_rpc(client_config, server_cmd)(dispatchers)
		end

		local package_root = client_config.root_dir and vim.fs.normalize(client_config.root_dir)
		local az = package_root and cw.find_workspace_from_dir(package_root)
		if not az or not cw.has_devcontainer_ancestor(az) then
			return local_fallback("not under az/.devcontainer")
		end

		local path_kind = cw.container_kind(package_root)
		local required = SERVER_KIND[client_config.name]
		if required and required ~= path_kind then
			return local_fallback(
				string.format("%s needs %s container, package is %s", client_config.name, required, path_kind)
			)
		end
		local kind = required or path_kind

		local exec_cmd = wrap_exec_in_package(az, package_root, server_cmd)
		local final_cmd = cli.cmd(package_root, "exec", unpack(exec_cmd))
		client_config._devcontainers.original_cmd = server_cmd
		client_config._devcontainers.cmd = final_cmd
		client_config._devcontainers.kind = kind

		local rpc_client, resolve = rpc.make_stub()

		coroutine.wrap(function()
			local ok, rpc_or_err = xpcall(function()
				local entry = ensure_kind(kind, az, package_root)
				if not entry then
					error(string.format("Could not start %s devcontainer", kind))
				end
				if opts.before_start then
					opts.before_start(client_config)
				end
				return paths.setup(client_config, final_cmd, az)(dispatchers)
			end, debug.traceback)

			if ok then
				resolve(rpc_or_err)
			else
				log.notify.error("LSP setup failed (%s): %s", kind, rpc_or_err or "?")
				resolve(nil, rpc_or_err)
			end
		end)()

		return rpc_client
	end
end

return M
