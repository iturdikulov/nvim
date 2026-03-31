return {
    {
        "milanglacier/minuet-ai.nvim",
        config = function()
            -- Invoke special functions to parse list
            require("minuet").setup({
                provider = "openai_compatible",
                n_completions = 3,
                -- I recommend beginning with a small context window size and incrementally
                -- expanding it, depending on your local computing power. A context window
                -- of 512, serves as an good starting point to estimate your computing
                -- power. Once you have a reliable estimate of your local computing power,
                -- -- you should adjust the context window to a larger value.
                context_window = 2048,
                request_timeout = 12,
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
                    openai_compatible = {
                        api_key = 'OPENROUTER_API_KEY',
                        end_point = 'https://openrouter.ai/api/v1/chat/completions',
                        model = 'google/gemini-3.1-flash-lite-preview',
                        name = 'Openrouter',
                        optional = {
                            max_tokens = 255,
                            provider = {
                                -- Prioritize throughput for faster completion
                                sort = 'throughput',
                                only = {'google-vertex'}
                            },
                        },
                    },
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
                    openai_fim_compatible_local = {
                        api_key = 'TERM',
                        name = 'Llama.cpp',
                        end_point = 'http://localhost:8001/v1/completions',
                        -- The model is set by the llama-cpp server and cannot be altered
                        -- post-launch.
                        model = 'PLACEHOLDER',
                        optional = {
                            max_tokens = 56,
                            top_p = 0.9,
                        },
                        -- Llama.cpp does not support the `suffix` option in FIM completion.
                        -- Therefore, we must disable it and manually populate the special
                        -- tokens required for FIM completion.
                        template = {
                            prompt = function(context_before_cursor, context_after_cursor, _)
                                return '<|fim_prefix|>'
                                    .. context_before_cursor
                                    .. '<|fim_suffix|>'
                                    .. context_after_cursor
                                    .. '<|fim_middle|>'
                            end,
                            suffix = false,
                        },
                    }
                },
            })
        end,
    },
    { "nvim-lua/plenary.nvim" },
    -- optional, if you are using virtual-text frontend, blink is not required.
    { "hrsh7th/nvim-cmp" },
}
