return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    dependencies = {
        "ravitemer/codecompanion-history.nvim",
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

        -- Expand cc to codecompanion in cmdline
        vim.cmd([[cab cc CodeCompanion]])

        require("codecompanion").setup({
            extensions = {
                history = {
                    enabled = true,
                    opts = {
                        picker = "default",
                    },
                },
            },
            strategies = {
                chat = { adapter = "gemini" },
                inline = {
                    adapter = "gemini",
                },
            },
            adapters = {
                http = {
                    gemini = function()
                        return require("codecompanion.adapters").extend(
                            "gemini",
                            {
                                env = {
                                    api_key = vim.env.GEMINI_API_KEY,
                                },
                                schema = {
                                    model = {
                                        default = "gemini-2.5-flash-lite", -- Use the name of your desired Ollama model
                                    },
                                },
                            }
                        )
                    end,
                },
            },
        })
    end,
}
