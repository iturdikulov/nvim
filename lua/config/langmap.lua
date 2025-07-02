local function escape(str)
    -- You need to escape these characters to work correctly
    local escape_chars = [[;,."|\]]
    return vim.fn.escape(str, escape_chars)
end

-- Recommended to use lua template string
-- NOTE: this potential source of mapping bugs
local en = [[jk`qwertyuiop[]asdfghl;'zxcvbnm.]]
local ru = [[нтёйцлыащшджкхъфвсупьгзэиячмеорю]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:ZXCVBNM<>]]
local ru_shift = [[ЁЙЦЛВАЩШДЖКХЪФВСУПЬНТГЗИЯЧМЕОРБЮ]]

vim.opt.langmap = vim.fn.join({
    -- | `to` should be first     | `from` should be second
    escape(ru_shift)
    .. ";"
    .. escape(en_shift),
    escape(ru) .. ";" .. escape(en),
}, ",")

-- Fix cyrillic mappings
vim.keymap.set("n", "<C-с>", "<C-d>")
vim.keymap.set("n", "<C-ш>", "<C-u>")
vim.keymap.set({"n", "x"}, "<leader>мфф", vim.lsp.buf.code_action)
vim.keymap.set({"n", "v", "i"}, "<M-в>", ":update<CR>")
