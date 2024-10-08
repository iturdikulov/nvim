local ok, supermaven = pcall(require, "supermaven-nvim")
if not ok then return end
supermaven.setup({
    keymaps = {
        accept_suggestion = "<C-l>",
        clear_suggestion = "<C-]>",
    },
    log_level = "off",
    disable_inline_completion = true,
    disable_keymaps = true
})
