return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local ok, _99 = pcall(require, "99")

        require("lualine").setup({
            options = {
                icons_enabled = true,
                section_separators = "",
                component_separators = "",
            },
            sections = {
                lualine_b = {
                    "branch",
                    "diff",
                    "diagnostics",
                    function()
                        return (ok and _99 and _99.get_model()) or ""
                    end,
                },
            },
        })
    end,
}
