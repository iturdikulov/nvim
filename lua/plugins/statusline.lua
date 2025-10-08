return {
    "nvim-lualine/lualine.nvim",
    config = function()
        require("lualine").setup({
            options = {
                icons_enabled = true,
                section_separators = "",
                component_separators = "",
            },
            sections = {
                lualine_b = { "branch", "diff", "diagnostics" },
            },
        })
    end,
}
