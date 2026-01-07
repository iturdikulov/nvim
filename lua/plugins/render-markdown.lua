return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    }, -- if you prefer nvim-web-devicons
    ft = { "markdown", "codecompanion", "vimwiki" },
    opts = {
        heading = {
            enabled = false,
        },
        bullet = {
            enabled = false,
        },
        sign = {
            enabled = false,
        },
        code = { style = "language" },
    },
}
