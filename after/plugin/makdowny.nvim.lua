if not pcall(require, "markdowny") then return end

vim.api.nvim_create_autocmd('FileType', {
    desc = 'markdowny.nvim keymaps',
    pattern = {'markdown'},
    callback = function()
        vim.keymap.set('v', '<M-b>', ":lua require('markdowny').bold()<cr>",
                       {buffer = 0})
        vim.keymap.set('v', '<M-i>', ":lua require('markdowny').italic()<cr>",
                       {buffer = 0})
        vim.keymap.set('v', '<M-k>', ":lua require('markdowny').link()<cr>",
                       {buffer = 0})
        vim.keymap.set('v', '<M-e>', ":lua require('markdowny').code()<cr>",
                       {buffer = 0})
    end
})
