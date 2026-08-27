--- Индикатор «LSP attach» в statusline для container и local LSP.
local M = {}

local pending = 0
---@type table<number, { bufnr: integer, supports_hints: boolean, started_at: integer, saw_progress: boolean, timer?: userdata }>
local watches = {}
---@type table<number, integer>
local progress_tokens = {}
local setup_done = false

local READY_TIMEOUT_MS = 20000
local AUX_LSP_GRACE_MS = 1500

local function sync_global()
	vim.g.lsp_attach_status = pending > 0 or nil
	pcall(vim.cmd.redrawstatus, { bang = true })
end

--- Увеличивает счётчик активных LSP/devcontainer операций.
function M.inc()
	pending = pending + 1
	sync_global()
end

--- Уменьшает счётчик; сбрасывает индикатор при достижении нуля.
function M.dec()
	if pending > 0 then
		pending = pending - 1
	end
	sync_global()
end

--- @param client vim.lsp.Client
local function should_track(client)
	return client.name ~= "null-ls"
end

--- @param client vim.lsp.Client
local function client_supports_inlay_hints(client)
	local cap = client.server_capabilities.inlayHintProvider
	return cap ~= nil and cap ~= false and cap ~= vim.NIL
end

--- @param bufnr integer
--- @param client_id integer
local function has_inlay_hints(bufnr, client_id)
	local ok, hints = pcall(vim.lsp.inlay_hint.get, { bufnr = bufnr, client_id = client_id })
	return ok and type(hints) == "table" and #hints > 0
end

--- @param watch { timer?: userdata }
local function stop_timer(watch)
	if not watch.timer then
		return
	end
	pcall(function()
		watch.timer:stop()
		watch.timer:close()
	end)
	watch.timer = nil
end

--- @param client_id integer
local function finish_watch(client_id)
	local watch = watches[client_id]
	if not watch then
		return
	end
	stop_timer(watch)
	watches[client_id] = nil
	progress_tokens[client_id] = nil
	M.dec()
end

--- @param client_id integer
local function try_finish(client_id)
	local watch = watches[client_id]
	if not watch then
		return
	end

	local client = vim.lsp.get_client_by_id(client_id)
	if not client then
		finish_watch(client_id)
		return
	end

	local active_progress = (progress_tokens[client_id] or 0) > 0
	local elapsed = vim.uv.now() - watch.started_at

	if watch.supports_hints then
		if has_inlay_hints(watch.bufnr, client_id) then
			finish_watch(client_id)
			return
		end
		-- vtsls/vue часто advertise hints, но на .vue они долго/никогда не приходят —
		-- не держим «LSP attach» до READY_TIMEOUT, считаем готовым после progress.
		if watch.saw_progress and not active_progress then
			finish_watch(client_id)
			return
		end
		if not active_progress and elapsed > AUX_LSP_GRACE_MS then
			finish_watch(client_id)
			return
		end
		if elapsed > READY_TIMEOUT_MS then
			finish_watch(client_id)
		end
		return
	end

	if active_progress then
		return
	end

	if watch.saw_progress or elapsed > AUX_LSP_GRACE_MS then
		finish_watch(client_id)
		return
	end

	if elapsed > READY_TIMEOUT_MS then
		finish_watch(client_id)
	end
end

--- Ждёт фактической готовности LSP (inlay hints / progress), а не только attach.
--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param opts? { skip_inc?: boolean }
local function watch_client_ready(client, bufnr, opts)
	opts = opts or {}
	local client_id = client.id
	if watches[client_id] then
		return
	end

	if not opts.skip_inc then
		M.inc()
	end

	watches[client_id] = {
		bufnr = bufnr,
		supports_hints = client_supports_inlay_hints(client),
		started_at = vim.uv.now(),
		saw_progress = false,
	}

	local timer = vim.uv.new_timer()
	watches[client_id].timer = timer
	timer:start(250, 250, function()
		vim.schedule(function()
			try_finish(client_id)
		end)
	end)
end

--- Регистрирует autocmd для attach/progress/error всех LSP клиентов.
function M.setup()
	if setup_done then
		return
	end
	setup_done = true

	local group = vim.api.nvim_create_augroup("LspAttachStatus", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client or not should_track(client) then
				return
			end
			local skip_inc = client.config._devcontainers ~= nil
			watch_client_ready(client, ev.buf, { skip_inc = skip_inc })
		end,
	})

	vim.api.nvim_create_autocmd("LspProgress", {
		group = group,
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client or not should_track(client) then
				return
			end

			local client_id = ev.data.client_id
			local kind = ev.match

			if kind == "begin" then
				progress_tokens[client_id] = (progress_tokens[client_id] or 0) + 1
				local watch = watches[client_id]
				if watch then
					watch.saw_progress = true
				end
			elseif kind == "end" then
				progress_tokens[client_id] = math.max(0, (progress_tokens[client_id] or 0) - 1)
				try_finish(client_id)
			end
		end,
	})

	vim.api.nvim_create_autocmd("LspNotify", {
		group = group,
		callback = function(ev)
			if ev.data.event ~= "init_error" then
				return
			end
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client or not should_track(client) then
				return
			end
			local client_id = ev.data.client_id
			if watches[client_id] then
				finish_watch(client_id)
			else
				M.dec()
			end
		end,
	})

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(ev)
			if watches[ev.data.client_id] then
				finish_watch(ev.data.client_id)
			end
		end,
	})
end

return M
