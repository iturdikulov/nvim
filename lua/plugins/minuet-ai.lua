return {
    {
        "milanglacier/minuet-ai.nvim",
        config = function()
            -- Invoke special functions to parse list
            require("minuet").setup({
                provider = "codestral",
                n_completions = 3,
                -- I recommend beginning with a small context window size and incrementally
                -- expanding it, depending on your local computing power. A context window
                -- of 512, serves as an good starting point to estimate your computing
                -- power. Once you have a reliable estimate of your local computing power,
                -- -- you should adjust the context window to a larger value.
                context_window = 8012,
                request_timeout = 8,
                virtualtext = {
                    -- Specify the filetypes to enable automatic virtual text completion,
                    -- e.g., { 'python', 'lua' }. Note that you can still invoke manual
                    -- completion even if the filetype is not on your auto_trigger_ft list.
                    auto_trigger_ft = {},
                    keymap = {
                        -- accept whole completion
                        accept = "<A-y>",
                        accept_line = "<A-Y>",
                        -- accept n lines (prompts for number)
                        -- e.g. "A-z 2 CR" will accept 2 lines
                        accept_n_lines = "<A-v>",
                        -- Cycle to next completion item, or manually invoke completion
                        next = "<M-n>",
                        -- Cycle to prev completion item, or manually invoke completion
                        prev = "<M-p>",
                    },
                    -- Whether show virtual text suggestion when the completion menu
                    -- (nvim-cmp or blink-cmp) is visible.
                    show_on_completion_menu = true,
                },
                provider_options = {
                    gemini = {
                        model = "gemini-2.5-flash-lite-preview-09-2025",
                        optional = {
                            max_tokens = 255,
                        },
                    },
                    codestral = {
                        optional = {
                            max_tokens = 256,
                            stop = { "\n\n" },
                        },
                    },
                    compatible = {
                        -- For Windows users, TERM may not be present in environment variables.
                        -- Consider using APPDATA instead.
                        --
                        api_key = "TERM",
                        name = "Ollama",
                        end_point = "http://localhost:11434/v1/chat/completions",
                        model = "gpt-oss:latest",
                        optional = {
                            max_completion_tokens = 128,
                            reasoning_effort = "low",
                        },
                    },
                },
            })
        end,
    },
    { "nvim-lua/plenary.nvim" },
    -- optional, if you are using virtual-text frontend, blink is not required.
    { "hrsh7th/nvim-cmp" },
}
