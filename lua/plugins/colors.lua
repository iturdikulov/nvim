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
                overrides = function()
                    return {
                        DiffAdd = { bg = "#173323" },
                        DiffDelete = { bg = "#2f181e" },
                        DiffChange = { bg = "#0d1726" },
                        DiffText = { bg = "#1d3d52" },
                    }
                end,
            })
            vim.cmd.colorscheme("kanso")
            vim.opt.background = "dark" -- or "light"
        end
    }
}
