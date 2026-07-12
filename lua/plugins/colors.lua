return {
    {
        "webhooked/kanso.nvim",
        lazy = false,
        config = function()
            require('kanso').setup({
                italic = false,
                transparency = false,
                theme = 'zen',
                minimal = true,
            })
            vim.cmd.colorscheme("kanso")
            vim.opt.background = "dark" -- or "light"
        end
    }
}
