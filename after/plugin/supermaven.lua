local ok, supermaven = pcall(require, "supermaven-nvim")
if not ok then return end
supermaven.setup({
    color = {
        suggestion_color = "#696969",
        cterm = 244,
    },
    keymaps = {
        accept_suggestion = "<C-f>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
    },
    log_level = "off",
})
