return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },

    config = function()
        vim.lsp.enable('clangd')
        vim.lsp.enable('gdscript')
        vim.lsp.enable('ruff')
        vim.lsp.enable('basedpyright')
        vim.lsp.enable('biome')
        vim.lsp.enable('gopls')
        vim.lsp.enable('lua_ls')
        vim.lsp.enable('bashls')
        vim.lsp.enable('asm_lsp')
        vim.lsp.config('rust_analyzer', {
            -- Server-specific settings. See `:help lsp-quickstart`
            settings = {
                ['rust-analyzer'] = {
                    diagnostics = {
                        enable = true;
                    }
                },
            },
        })
        vim.lsp.enable('rust_analyzer')
        vim.lsp.enable('emmet_language_server')

        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })


        -- GLOBAL LSP MAPPING DEFAULTS
        -- grr gra grn gri i_CTRL-S These GLOBAL keymaps are created unconditionally when Nvim starts:
        -- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
        -- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
        -- "grr" is mapped in Normal mode to vim.lsp.buf.references()
        -- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
        -- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
        -- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
        -- [d next diagnostics
        -- ]d previous diagnostics

        -- CUSTOM LSP MAPPINGS
        local augroup = vim.api.nvim_create_augroup
        local autocmd = vim.api.nvim_create_autocmd
        local LSPGroup = augroup('LSPGroup', {})
        autocmd('LspAttach', {
            group = LSPGroup,
            callback = function(e)
                local opts = { buffer = e.buf }
                vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set("n", "go", function() vim.lsp.buf.workspace_symbol() end, opts)
                vim.keymap.set("n", "gl", function() vim.diagnostic.open_float() end, opts)
            end
        })

    end
}
