local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
local is_linux = vim.loop.os_uname().sysname == 'Linux';
require("lazy").setup({
    --[[
          Base dependencies
     --]]
    { "nvim-lua/plenary.nvim" },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate"
    },
    { "LunarVim/bigfile.nvim" },
    { "folke/which-key.nvim" },
    --[[
          Make nvim looking good
     --]]
    { "Inom-Turdikulov/alabaster.nvim" },
    { "tjdevries/express_line.nvim" },
    {
        "numToStr/Comment.nvim",
        lazy = false,
        dependencies = {
            { "JoosepAlviste/nvim-ts-context-commentstring" }, -- To fix comments in react templates
        }
    },
    { "folke/todo-comments.nvim",       dependencies = { "nvim-lua/plenary.nvim" } },
    --[[
          Improve core functional
     --]]
    { -- Collection of various small independent plugins/modules
        'echasnovski/mini.nvim',
        config = function()
        end,
    },
    { -- Fuzzy Finder (files, lsp, etc)
        'nvim-telescope/telescope.nvim',
        event = 'VeryLazy',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { -- If encountering errors, see telescope-fzf-native README for install instructions
                'nvim-telescope/telescope-fzf-native.nvim',

                -- `build` is used to run some command when the plugin is installed/updated.
                -- This is only run then, not every time Neovim starts up.
                build = 'make',

                -- `cond` is a condition used to determine whether this plugin should be
                -- installed and loaded.
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
            { 'nvim-telescope/telescope-ui-select.nvim' },

            -- Useful for getting pretty icons, but requires special font.
            --  If you already have a Nerd Font, or terminal set up with fallback fonts
            --  you can enable this
            { 'nvim-tree/nvim-web-devicons' }
        }
    },
    {
        "ThePrimeagen/harpoon", -- TODO: switch to main branch
        branch = "harpoon2",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
    },
    { "kevinhwang91/nvim-ufo",       dependencies = "kevinhwang91/promise-async" },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        after = "nvim-treesitter",
        requires = "nvim-treesitter/nvim-treesitter",
    },
    {
        'AckslD/nvim-FeMaco.lua',
    },
    {
        "SuchithSridhar/nvim-treesitter-context", -- TODO: swap to upstream
        after = "nvim-treesitter",
        requires = "nvim-treesitter/nvim-treesitter",
    },
    "Darazaki/indent-o-matic",
    "tpope/vim-eunuch",
    "okuuva/auto-save.nvim",

    --[[
          Better VCS support
     --]]
    "mbbill/undotree",
    "tpope/vim-fugitive",
    "lewis6991/gitsigns.nvim", -- Git decorations
    --[[
          LSP+
     --]]
    {
        "supermaven-inc/supermaven-nvim",
        enabled = is_linux
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            {
                "L3MON4D3/LuaSnip",
                dependencies = {
                    "rafamadriz/friendly-snippets",
                    "saadparwaiz1/cmp_luasnip",
                },
            },
        },
    },
    "Teatek/gdscript-extended-lsp.nvim",
    { "barreiroleo/ltex-extra.nvim", enabled = is_linux },
    { "lervag/vimtex" },

    --[[
          Code quality and documentation
     --]]
    { "stevearc/conform.nvim",       enabled = is_linux }, -- Formatting
    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    },
    { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "KabbAmine/zeavim.vim", enabled = is_linux },

    --[[
          Debugging & Tasks
     --]]
    "mfussenegger/nvim-dap",
    { "rcarriga/nvim-dap-ui",         dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-treesitter/nvim-treesitter",
        },
    },
    { "mfussenegger/nvim-dap-python", dependencies = { "mfussenegger/nvim-dap" } },
    { "mxsdev/nvim-dap-vscode-js",    dependencies = { "mfussenegger/nvim-dap" } },
    {
        "nvim-telescope/telescope-dap.nvim",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    },

    --[[
          Code execution and test running
     --]]
    { "tpope/vim-dispatch" },
    {
        "jubnzv/mdeval.nvim",
    },
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter", -- Language specific plugins
            "nvim-neotest/neotest-python",
            "rouge8/neotest-rust",
            "nvim-neotest/neotest-go",
        },
    },

    --[[
          Databases
     --]]
    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = {
            { "tpope/vim-dadbod",                     lazy = true },
            { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
        },
        cmd = {
            "DBUI",
            "DBUIToggle",
            "DBUIAddConnection",
            "DBUIFindBuffer",
        },
    },

    --[[
          Add support additinal syntax and files specific features
     --]]
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },
    "antonk52/markdowny.nvim",
    "Glench/Vim-Jinja2-Syntax",
    "phelipetls/jsonpath.nvim", -- WARNING: this require tresitter which I installed manually (NixOS)
    { "jamessan/vim-gnupg", enabled = is_linux },
})
