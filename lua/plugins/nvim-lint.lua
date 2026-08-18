return {
	"mfussenegger/nvim-lint",
	enabled = not require("config.platform").is_windows,
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			vue = { "eslint_d" },
		}

		-- Те же корни, что container_lsp_roots в lsp.lua
		local home = vim.uv.os_homedir()
		local container_lint_roots = {
			[vim.fs.normalize(vim.fs.joinpath(home, "Desktop", "atd", "az-containers"))] = true,
		}

		local eslint_root_markers = {
			"eslint.config.mjs",
			"eslint.config.js",
			"eslint.config.cjs",
			".eslintrc.cjs",
			".eslintrc.js",
			".eslintrc.json",
		}

		local container_up_cache = {
			workspace = nil,
			up = false,
			checked_at = 0,
		}

		---@param workspace string
		---@return boolean
		local function container_is_up(workspace)
			local now = vim.uv.now()
			if container_up_cache.workspace == workspace and now - container_up_cache.checked_at < 5000 then
				return container_up_cache.up
			end
			local ok, cli = pcall(require, "devcontainers.cli")
			local up = ok and cli.container_is_running(workspace) or false
			container_up_cache = {
				workspace = workspace,
				up = up,
				checked_at = now,
			}
			return up
		end

		---@param workspace string
		---@param host_path string
		---@return string
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

		---@param bufnr integer
		---@return string?
		local function eslint_package_root(bufnr)
			return vim.fs.root(bufnr, eslint_root_markers)
		end

		---@param linter lint.Linter
		---@return lint.Linter
		local function wrap_eslint_d_for_container(linter)
			if linter.name ~= "eslint_d" then
				return linter
			end

			local bufnr = vim.api.nvim_get_current_buf()
			local package_root = eslint_package_root(bufnr)
			if package_root then
				-- eslint_d ищет конфиг от cwd; для монорепы нужен пакет, не корень workspace
				linter.cwd = package_root
			end

			local workspace = vim.fs.root(bufnr, ".devcontainer")
			if not workspace then
				return linter
			end
			workspace = vim.fs.normalize(workspace)
			if not container_lint_roots[workspace] or not container_is_up(workspace) then
				return linter
			end

			local ok, cli = pcall(require, "devcontainers.cli")
			if not ok then
				return linter
			end

			local host_fname = vim.api.nvim_buf_get_name(bufnr)
			local container_fname = to_container_path(workspace, host_fname)
			local container_pkg = package_root and to_container_path(workspace, package_root) or "/workspace"
			-- devcontainer exec стартует с cwd=/workspace → eslint_d timeout без cd в пакет
			local shell = string.format(
				"cd %s && exec eslint_d --format json --stdin --stdin-filename %s",
				vim.fn.shellescape(container_pkg),
				vim.fn.shellescape(container_fname)
			)
			local prefix = cli.cmd(workspace, "exec", "sh", "-c", shell)
			linter.cmd = prefix[1]
			linter.args = vim.list_slice(prefix, 2)
			return linter
		end

		-- stdin-буфер: сохранять не нужно. Раньше только InsertLeave/Write → в insert «молчал».
		local lint_timer = vim.uv.new_timer()
		local lint_debounce_ms = 500

		local function run_lint()
			lint.try_lint(nil, {
				wrap_linter = wrap_eslint_d_for_container,
				ignore_errors = true,
			})
		end

		---@param wait integer|nil
		local function schedule_lint(wait)
			lint_timer:stop()
			lint_timer:start(wait or lint_debounce_ms, 0, vim.schedule_wrap(run_lint))
		end

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
			group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
			callback = function()
				schedule_lint(0)
			end,
		})

		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "TextChangedI" }, {
			group = vim.api.nvim_create_augroup("nvim_lint_change", { clear = true }),
			callback = function()
				schedule_lint(lint_debounce_ms)
			end,
		})
	end,
}
