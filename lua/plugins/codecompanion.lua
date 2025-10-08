return {
    "olimorris/codecompanion.nvim",
    config = function()
        local default_model = "x-ai/grok-code-fast-1"
        local available_models = {
            "anthropic/claude-sonnet-4.5",
            "google/gemini-2.5-flash",
            "openai/gpt-4o-mini",
            "x-ai/grok-code-fast-1",
        }
        local current_model = default_model

        local function select_model()
            vim.ui.select(available_models, {
                prompt = "Select  Model:",
            }, function(choice)
                if choice then
                    current_model = choice
                    vim.notify("Selected model: " .. current_model)
                end
            end)
        end

        require("codecompanion").setup({
            strategies = {
                chat = {
                    adapter = "openrouter",
                    keymaps = {
                        submit = {
                            modes = { n = "<C-s>", i = "<C-s>" },
                            description = "Submit",
                            callback = function(chat)
                                chat:apply_model(current_model)
                                chat:submit()
                            end,
                        },
                    },
                },
                inline = {
                    adapter = "openrouter",
                },
            },
            adapters = {
                http = {
                    openrouter = function()
                        return require("codecompanion.adapters").extend(
                            "openai_compatible",
                            {
                                env = {
                                    url = "https://openrouter.ai/api",
                                    api_key = "OPENROUTER_API_KEY",
                                    chat_url = "/v1/chat/completions",
                                },
                                schema = {
                                    model = {
                                        default = current_model,
                                    },
                                },
                            }
                        )
                    end,
                },
            },
        })

        vim.keymap.set(
            { "n", "v" },
            "<leader>ck",
            "<cmd>CodeCompanionActions<cr>",
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            { "n", "v" },
            "<leader>a",
            "<cmd>CodeCompanionChat Toggle<cr>",
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            "v",
            "ga",
            "<cmd>CodeCompanionChat Add<cr>",
            { noremap = true, silent = true }
        )

        vim.keymap.set(
            "n",
            "<leader>cs",
            select_model,
            { desc = "Select Gemini Model" }
        )
        -- Expand 'cc' into 'CodeCompanion' in the command line
        vim.cmd([[cab cc CodeCompanion]])
    end,

    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-lua/plenary.nvim",
    },
}
