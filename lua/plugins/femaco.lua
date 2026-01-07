return {
    {
        "AckslD/nvim-FeMaco.lua",
        config = function()
            local clip_val = require("femaco.utils").clip_val
            require("femaco").setup({
                ensure_newline = function(base_filetype)
                    return base_filetype == "markdown"
                end,
                float_opts = function(code_block)
                    return {
                        relative = "cursor",
                        width = clip_val(
                            5,
                            120,
                            vim.api.nvim_win_get_width(0) - 10
                        ), -- TODO how to offset sign column etc?
                        height = clip_val(
                            5,
                            math.max(15, #code_block.lines),
                            vim.api.nvim_win_get_height(0) - 6
                        ),
                        anchor = "NW",
                        row = 0,
                        col = 0,
                        style = "minimal",
                        border = "rounded",
                        zindex = 40,
                    }
                end,
            })
            vim.keymap.set("n", "<leader>te", function()
                require("femaco.edit").edit_code_block()
            end, { desc = "Edit code block" })
        end,
    },
}
