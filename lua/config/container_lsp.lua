--- Generic devcontainer LSP wrapper. The package's nearest `.devcontainer`
--- selects its image; package type and workspace layout are not encoded here.
local M = {}

---@param cmd string[]|fun(config: vim.lsp.ClientConfig): string[]
---@param opts? table
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers, config: vim.lsp.ClientConfig): vim.lsp.rpc.PublicClient
function M.lsp_cmd(cmd, opts)
	return require("devcontainers").lsp_cmd(cmd, opts)
end

return M
