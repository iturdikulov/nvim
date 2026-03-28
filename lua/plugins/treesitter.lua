return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ':TSUpdate',
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
        -- Enable treesitter folding
        -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        local status_ok, ts = pcall(require, "nvim-treesitter.configs")

        if not status_ok then
            ts = require("nvim-treesitter.config")
            return
        end

        ts.setup({
            -- Add languages to be installed here that you want installed for treesitter
            ensure_installed = {
                "comment",
                "bash",
                "c",
                "cpp",
                "dockerfile",
                "git_config",
                "git_rebase",
                "gitattributes",
                "gitcommit",
                "gitignore",
                "go",
                "gdscript",
                "javascript",
                "json",
                "jsonc",
                "lua",
                "make",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "rust",
                "toml",
                "tsx",
                "typescript",
                "vim",
                "vue",
                "vimdoc",
                "yaml",
                "zig",
            },

            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<c-space>",
                    node_incremental = "<c-space>",
                    scope_incremental = "<c-s>",
                    node_decremental = "<M-space>",
                },
            },
            -- Select, move, and swap code structures
            textobjects = {
                -- Selection in operator-pending or visual mode (v, d, y, etc.):
                select = {
                    enable = true,
                    lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ["aa"] = "@parameter.outer", -- select a parameter (including commas, etc.)
                        ["ia"] = "@parameter.inner", -- select inside a parameter
                        ["af"] = "@function.outer", -- select entire function (definition + body)
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        -- You can optionally set descriptions to the mappings (used in the desc parameter of
                        -- nvim_buf_set_keymap) which plugins like which-key display
                        ["ic"] = {
                            query = "@class.inner",
                            desc = "Select inner part of a class region",
                        },
                        -- You can also use captures from other query groups like `locals.scm`
                        ["as"] = {
                            query = "@local.scope",
                            query_group = "locals",
                            desc = "Select language scope",
                        },
                        -- Fence blocks
                        ["iq"] = "@code_fence.content",
                        ["aq"] = "@code_fence.outer",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]]"] = "@class.outer",
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                        ["]["] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[["] = "@class.outer",
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                        ["[]"] = "@class.outer",
                    },
                },
                swap = {
                    enable = true,
                    swap_next = {
                        ["<leader>a"] = "@parameter.inner",
                    },
                    swap_previous = {
                        ["<leader>A"] = "@parameter.inner",
                    },
                },
            },
        })
    end,
}
