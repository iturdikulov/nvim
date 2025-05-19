return {
    {
        'milanglacier/minuet-ai.nvim',
        config = function()
            -- Invoke special functions to parse list
            require('minuet').setup {
                provider = 'openai_compatible',
                request_timeout = 5,
                throttle = 1500, -- Increase to reduce costs and avoid rate limits
                debounce = 600, -- Increase to reduce costs and avoid rate limits
                virtualtext = {
                    -- Specify the filetypes to enable automatic virtual text completion,
                    -- e.g., { 'python', 'lua' }. Note that you can still invoke manual
                    -- completion even if the filetype is not on your auto_trigger_ft list.
                    auto_trigger_ft = {},
                    keymap = {
                        -- accept whole completion
                        accept = '<A-y>',
                        -- accept n lines (prompts for number)
                        -- e.g. "A-z 2 CR" will accept 2 lines
                        accept_n_lines = '<A-z>',
                        -- Cycle to next completion item, or manually invoke completion
                        next = '<M-f>',
                        -- Cycle to prev completion item, or manually invoke completion
                        prev = '<C-f>',
                    },
                    -- Whether show virtual text suggestion when the completion menu
                    -- (nvim-cmp or blink-cmp) is visible.
                    show_on_completion_menu = true,
                },
                provider_options = {
                    openai_compatible = {
                        api_key = 'OPENROUTER_API_KEY',
                        end_point = 'https://openrouter.ai/api/v1/chat/completions',
                        model = 'openai/gpt-4o-mini',
                        name = 'Openrouter',
                        optional = {
                            max_tokens = 56,
                            top_p = 0.9,
                            provider = {
                                -- Prioritize throughput for faster completion
                                sort = 'throughput',
                            },
                        },
                    },
                },

            }
            end,
        },
        { 'nvim-lua/plenary.nvim' },
        -- optional, if you are using virtual-text frontend, blink is not required.
        { 'Saghen/blink.cmp' },
    }
