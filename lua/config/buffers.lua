local M = {}

--- Удаляет текущий буфер через Snacks.bufdelete; после последнего — dashboard.
function M.delete()
	local ok, Snacks = pcall(require, "snacks")
	if not ok then
		vim.cmd("bd")
		return
	end

	Snacks.bufdelete()
	vim.schedule(function()
		local buf = vim.api.nvim_get_current_buf()
		local empty = vim.api.nvim_buf_get_name(buf) == ""
			and vim.bo[buf].buftype == ""
			and vim.bo[buf].filetype == ""
			and not vim.bo[buf].modified
		if empty then
			Snacks.dashboard.open({
				buf = buf,
				win = vim.api.nvim_get_current_win(),
			})
		end
	end)
end

return M
