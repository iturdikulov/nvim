return {
    "alexghergh/nvim-tmux-navigation",
    config = function()
        local nvim_tmux_nav = require("nvim-tmux-navigation")

        vim.keymap.set(
            { "n", "v", "i" },
            "<M-h>",
            nvim_tmux_nav.NvimTmuxNavigateLeft
        )
        vim.keymap.set(
            { "n", "v", "i" },
            "<M-j>",
            nvim_tmux_nav.NvimTmuxNavigateDown
        )
        vim.keymap.set(
            { "n", "v", "i" },
            "<M-k>",
            nvim_tmux_nav.NvimTmuxNavigateUp
        )
        vim.keymap.set(
            { "n", "v", "i" },
            "<M-l>",
            nvim_tmux_nav.NvimTmuxNavigateRight
        )
    end,
}
