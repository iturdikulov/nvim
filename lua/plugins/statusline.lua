return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local ok, _99 = pcall(require, "99")

        require("lualine").setup({
            options = {
                icons_enabled = true,
                section_separators = "",
                component_separators = "",
                globalstatus = true,
            },
            sections = {
                lualine_b = {
                    "branch",
                    "diff",
                    "diagnostics",
                    {
                        function()
                            return vim.g.lsp_attach_status and "LSP attach" or ""
                        end,
                        color = { fg = "#E5C07B" },
                    },
                    function()
                        return (ok and _99 and _99.get_model()) or ""
                    end,
                },
            },
        })
    end,
}
