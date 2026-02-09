local M = {}

--- Open a file. Provided for integration purposes.
--- Helps open files from developer extensions.
---@param filename string
---@param line integer
---@param column integer
function M.open_file(filename, line, column)
	-- Open the file in the current window
  vim.cmd('edit ' .. vim.fn.fnameescape(filename))

	-- Set the cursor (line is 1-indexed, column is 0-indexed in API)
	if line and column then
		vim.api.nvim_win_set_cursor(0, { line, column - 1 })
	end
end

return M
