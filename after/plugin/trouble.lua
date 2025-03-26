local ok, trouble = pcall(require, "trouble")
if not ok then return end

trouble.setup {}
local map = function(lhs, rhs, desc)
    if desc then desc = "[Trouble] " .. desc end

    vim.keymap.set("n", lhs, rhs, {silent = true, desc = desc})
end

map("<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics")
map("<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics")
map("<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", "Symbols")
map("<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "LSP Definitions / references / ...")
map("<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List")
map("<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List")
map("<leader>xt", "<cmd>Trouble todo<cr>", "Todo list")
