return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        vim.keymap.set({ "n", "x" }, "<leader>ae", function()
            vim.cmd("CodeCompanionActions")
        end, { desc = "Open Code Companion Actions" })
        vim.keymap.set({ "n", "x" }, "<leader>aa", function()
            vim.cmd("CodeCompanionChat Toggle")
        end, { desc = "Open Code Companion Chat" })
        vim.keymap.set({ "n", "v" }, "ga", function()
            vim.cmd("CodeCompanionChat Add")
        end, { desc = "Add selected code to chat" })

        vim.cmd([[cab cc CodeCompanion]])

        require("codecompanion").setup({
            interactions = {
                chat = { adapter = "gemini_cli" },
                inline = { adapter = "gemini_cli" },
            },
        })
    end,
}

