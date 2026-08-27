--- Корни проектов az-monorepo (маркер — файл `az` в корне) для container-LSP/lint.
local M = {}

local WORKSPACE_MARKER = "az"

--- @param dir string|nil
--- @return string?
local function find_workspace_from_dir(dir)
	if not dir or dir == "" then
		return nil
	end
	dir = vim.fs.normalize(dir)
	while dir and dir ~= "/" do
		if vim.uv.fs_stat(vim.fs.joinpath(dir, WORKSPACE_MARKER)) then
			return dir
		end
		dir = vim.fs.dirname(dir)
	end
	return nil
end

--- @param bufnr integer
--- @return string?
function M.workspace_root(bufnr)
	return vim.fs.root(bufnr, WORKSPACE_MARKER)
end

--- @param dir string|nil
--- @return boolean
function M.is_under_workspace(dir)
	return find_workspace_from_dir(dir) ~= nil
end

--- @param dir string|nil
--- @return boolean
function M.has_devcontainer_ancestor(dir)
	if not dir or dir == "" then
		return false
	end
	dir = vim.fs.normalize(dir)
	while dir and dir ~= "/" do
		if vim.uv.fs_stat(vim.fs.joinpath(dir, ".devcontainer")) then
			return true
		end
		dir = vim.fs.dirname(dir)
	end
	return false
end

--- @param bufnr integer
--- @param workspace_root string
--- @return string?
local function packages_module_root(bufnr, workspace_root)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	if fname == "" then
		return nil
	end
	local path = vim.fs.normalize(fname)
	local packages_dir = vim.fs.joinpath(workspace_root, "packages")
	if not vim.startswith(path, packages_dir .. "/") then
		return nil
	end
	local rel = path:sub(#packages_dir + 2)
	local module = rel:match("^([^/]+)")
	if not module then
		return nil
	end
	return vim.fs.joinpath(packages_dir, module)
end

--- Имя пакета packages/<name> для path под monorepo.
--- @param dir string|nil
--- @return string?
function M.package_name(dir)
	local workspace = find_workspace_from_dir(dir)
	if not workspace or not dir then
		return nil
	end
	dir = vim.fs.normalize(dir)
	local packages_dir = vim.fs.joinpath(workspace, "packages") .. "/"
	if not vim.startswith(dir, packages_dir) then
		return nil
	end
	return dir:sub(#packages_dir + 1):match("^([^/]+)")
end

--- `*-frontend` → alpine; всё остальное → python (ltms-backend).
--- @param dir string|nil
--- @return "frontend"|"backend"
function M.container_kind(dir)
	local name = M.package_name(dir)
	if name and name:match("%-frontend$") then
		return "frontend"
	end
	return "backend"
end

--- @param kind "frontend"|"backend"
--- @param workspace string
--- @return string
function M.devcontainer_config(kind, workspace)
	return vim.fs.joinpath(workspace, ".devcontainer", kind, "devcontainer.json")
end

--- Маркер только строго внутри workspace (не сам корень monorepo).
--- @param bufnr integer
--- @param workspace_root string
--- @param file_markers string[]
--- @return string?
local function find_marker_root(bufnr, workspace_root, file_markers)
	local best = nil
	for _, marker in ipairs(file_markers) do
		local marker_root = vim.fs.root(bufnr, marker)
		if marker_root then
			marker_root = vim.fs.normalize(marker_root)
			if vim.startswith(marker_root, workspace_root .. "/") then
				if not best or #marker_root > #best then
					best = marker_root
				end
			end
		end
	end
	return best
end

--- Корень LSP: file-маркеры → packages/xxx. Корень monorepo не используется.
--- @param bufnr integer
--- @param file_markers string[]|nil
--- @return string|nil
function M.find_project_root(bufnr, file_markers)
	local workspace_root = M.workspace_root(bufnr)
	if not workspace_root then
		return nil
	end
	workspace_root = vim.fs.normalize(workspace_root)

	if file_markers then
		local marker_root = find_marker_root(bufnr, workspace_root, file_markers)
		if marker_root then
			return marker_root
		end
	end

	return packages_module_root(bufnr, workspace_root)
end

--- @param dir string|nil
--- @return string?
function M.find_workspace_from_dir(dir)
	return find_workspace_from_dir(dir)
end

return M
