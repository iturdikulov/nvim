if not pcall(require, "nvim-treesitter") then return end

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
    require('nvim-treesitter.configs').setup {
        -- Add languages to be installed here that you want installed for treesitter
        -- TODO: merge with markdown fenced languages
        ensure_installed = {
            "c",      "cpp",        "lua",
            "vim",    "vimdoc",     "query",
            "elixir", "heex",       "javascript",
            "tsx",    "typescript", "html",
            "css",    "markdown",   "markdown_inline",
            "scss",   "bash",       "rust",
            "ruby",   "go",         "gdscript",
            "python", "json",       "toml",
            "tsv",    "csv",        "yaml",
            "nix",    "sql",        "pascal"
        },

        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = false,
        -- Install languages synchronously (only applied to `ensure_installed`)
        sync_install = false,
        -- List of parsers to ignore installing
        ignore_install = {},
        modules = {},
        highlight = {
            enable = true,

            -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
            -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
            -- Using this option may slow down your editor, and you may see some duplicate highlights.
            -- Instead of true it can also be a list of languages
            additional_vim_regex_highlighting = false,
            disable = { "latex" }  -- vimtex claims that their coloration is more accurate than what tree-sitter
        },
        indent = {
            enable = true,
            disable = {
                "markdown", -- indentation at bullet points is worse
            },
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = '<m-space>',
                node_incremental = '<m-space>',
                scope_incremental = '<m-s>',
                node_decremental = '<M-q>',
            },
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ['aa'] = '@parameter.outer',
                    ['ia'] = '@parameter.inner',
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ['ic'] = '@class.inner',
                    ['ab'] = '@block.outer',
                    ['ib'] = '@block.inner',
                },
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    [']m'] = '@function.outer',
                    [']]'] = '@class.outer',
                },
                goto_next_end = {
                    [']M'] = '@function.outer',
                    [']['] = '@class.outer',
                },
                goto_previous_start = {
                    ['[m'] = '@function.outer',
                    ['[['] = '@class.outer',
                },
                goto_previous_end = {
                    ['[M'] = '@function.outer',
                    ['[]'] = '@class.outer',
                },
            },
            -- swap = {
            --     enable = true,
            --     swap_next = {
            --         ['<leader>a'] = '@parameter.inner',
            --     },
            --     swap_previous = {
            --         ['<leader>A'] = '@parameter.inner',
            --     },
            -- },
        },
    }
end, 0)
