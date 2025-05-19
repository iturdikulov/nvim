return {
    "nvim-treesitter/nvim-treesitter",
        config = function()
            require"nvim-treesitter.configs".setup {
                -- A list of parser names, or "all" (the listed parsers MUST always be installed)
                ensure_installed = { "c", "python", "go", "rust", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline"},
            }
    end,
}
