return {
    "Pocco81/auto-save.nvim",
    config = function()
        require("auto-save").setup({
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            condition = function(buf)
                local fn = vim.fn
                local utils = require("auto-save.utils.data")
                if
                    fn.getbufvar(buf, "&modifiable") == 1
                    and utils.not_in(fn.getbufvar(buf, "&filetype"), {})
                    and fn.expand('%:t'):match("TODO")
                then
                    return true -- met condition(s), can save
                end
                return false -- can't save
            end,
        })
    end,
}
