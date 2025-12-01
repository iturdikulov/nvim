return {
    "okuuva/auto-save.nvim",
    version = "^1.0.0",
    cmd = "ASToggle", -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    config = function()
        -- Global flag for force-enabling auto-save
        vim.g.auto_save_force = false

        vim.keymap.set("n", "<leader>as", function()
            vim.g.auto_save_force = not vim.g.auto_save_force
            vim.notify(
                "Auto-save force mode: "
                    .. (vim.g.auto_save_force and "enabled" or "disabled"),
                vim.log.levels.INFO
            )
        end, { desc = "Toggle force auto-save" })

        require("auto-save").setup({
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            condition = function(buf)
                local fn = vim.fn
                local utils = require("auto-save.utils.data")

                -- Autosave if NVIM_AUTOSAVE enviroment set to 1
                if vim.env.NVIM_AUTOSAVE == "1" or vim.g.auto_save_force then
                    return true
                end
                -- Autosave TODO... files
                if
                    fn.getbufvar(buf, "&modifiable") == 1
                    and utils.not_in(fn.getbufvar(buf, "&filetype"), {})
                    and (fn.expand("%:t"):match("TODO") or fn.expand("%:t"):match("QuickNote"))
                then
                    return true -- met condition(s), can save
                end
                return false -- can't save
            end,
        })
    end,
}
