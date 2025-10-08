return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "dmitmel/cmp-cmdline-history",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "f3fora/cmp-spell",
    },

    config = function()
        local cmp = require("cmp")
        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),

                ["<C-y>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            select = true,
                        })
                    else
                        fallback()
                    end
                end),

                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                {
                    name = "nvim_lsp",
                    option = {
                        markdown_oxide = {
                            keyword_pattern = [[\(\k\| \|\/\|#\)\+]],
                        },
                    },
                },
                { name = "luasnip" }, -- For luasnip users.
                { name = "path", max_item_count = 3 },
                { name = "buffer", max_item_count = 5 },
                { name = "codecompanion" },
                {
                    name = "spell",
                    option = {
                        keep_all_entries = false,
                        enable_in_context = function()
                            return require("cmp.config.context").in_treesitter_capture(
                                "spell"
                            )
                        end,
                        preselect_correct_word = true,
                    },
                    max_item_count = 3,
                },
            }),
        })

        -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = 'cmdline_history', max_item_count = 3 },
                { name = "cmdline", max_item_count = 10 },
                { name = "path", max_item_count = 3 },
                { name = "buffer", max_item_count = 3 },
            }),
        })

        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = 'cmdline_history', max_item_count = 3 },
                { name = "buffer", max_item_count = 3 },
            }),
        })

        -- LSP
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        local base_config_lsp = {
            "clangd",
            "gdscript",
            "ruff",
            "biome",
            "gopls",
            "bashls",
            "asm_lsp",
            "ts_ls",
            "dockerls",
            "yamlls",
        }

        for _, lsp in ipairs(base_config_lsp) do
            vim.lsp.config(lsp, {
                capabilities = capabilities,
            })
            vim.lsp.enable(lsp)
        end

        vim.lsp.config("texlab", {
            capabilities = capabilities,
            settings = {
                texlab = {
                    bibtexFormatter = "texlab",
                    build = {
                        args = {
                            "-pdf",
                            "-interaction=nonstopmode",
                            "-synctex=1",
                            "%f",
                        },
                        executable = "latexmk",
                        forwardSearchAfter = false,
                        onSave = true,
                    },
                    chktex = {
                        onEdit = false,
                        onOpenAndSave = true,
                    },
                    diagnosticsDelay = 300,
                    formatterLineLength = 80,
                    forwardSearch = {
                        executable = "sioyek",
                        args = {
                            "--reuse-window",
                            "--execute-command",
                            "toggle_synctex",
                            "--inverse-search",
                            'texlab inverse-search -i "%%1" -l %%2',
                            "--forward-search-file",
                            "%f",
                            "--forward-search-line",
                            "%l",
                            "%p",
                        },
                    },
                    latexFormatter = "latexindent",
                    latexindent = {
                        modifyLineBreaks = false,
                    },
                },
            },
        })
        vim.lsp.enable("texlab")

        vim.lsp.config("basedpyright", {
            capabilities = capabilities,
            settings = {
                basedpyright = {
                    typeCheckingMode = "basic", -- off, basic, standard, strict, all
                    analysis = {
                        inlayHints = {
                            callArgumentNames = false,
                        },
                    },
                },
            },
        })
        vim.lsp.enable("basedpyright")

        vim.lsp.config("lua_ls", {
            capabilities = capabilities,
            settings = {
                Lua = {
                    telemetry = { enable = false },
                    hint = { enable = true },
                },
            },
        })
        vim.lsp.enable("lua_ls")

        vim.lsp.config("rust_analyzer", {
            -- Server-specific settings. See `:help lsp-quickstart`
            settings = {
                ["rust-analyzer"] = {
                    diagnostics = {
                        enable = true,
                    },
                },
            },
        })
        vim.lsp.enable("rust_analyzer")

        vim.lsp.config("emmet_language_server", {
            filetypes = {
                "css",
                "eruby",
                "html",
                "javascript",
                "javascriptreact",
                "less",
                "sass",
                "scss",
                "pug",
                "typescriptreact",
                "smarty",
            },
        })
        vim.lsp.enable("emmet_language_server")

        -- Markdown oxide
        vim.lsp.config("markdown_oxide", {
            -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
            -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
            capabilities = vim.tbl_deep_extend("force", capabilities, {
                workspace = {
                    didChangeWatchedFiles = {
                        dynamicRegistration = true,
                    },
                },
            }),
        })
        vim.lsp.enable("markdown_oxide")

        vim.lsp.config("cssls", {
            capabilities = vim.tbl_deep_extend("force", capabilities, {
                textDocument = {
                    completion = {
                        completionItem = {
                            snippetSupport = true
                        },
                    },
                },
            }),
        })
        vim.lsp.enable("cssls")

        vim.lsp.config("html", {
            capabilities = vim.tbl_deep_extend("force", capabilities, {
                textDocument = {
                    completion = {
                        completionItem = {
                            snippetSupport = true
                        },
                    },
                },
            }),
            filetypes = { "html", "templ", "smarty", "jinja" }
        })
        vim.lsp.enable("html")

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

        -- Enable inlay hints by default
        vim.lsp.inlay_hint.enable()

        -- Enable formatting on-type if possible
        vim.lsp.on_type_formatting.enable()

        local augroup = vim.api.nvim_create_augroup
        local autocmd = vim.api.nvim_create_autocmd
        local LSPGroup = augroup("LSPGroup", {})
        autocmd("LspAttach", {
            group = LSPGroup,
            callback = function(e)
                local map = function(lhs, rhs, desc)
                    if desc then
                        desc = "[LSP] " .. desc
                    end

                    vim.keymap.set(
                        "n",
                        lhs,
                        rhs,
                        { buffer = e.buf, desc = desc }
                    )
                end

                -- Custom LSP mappings
                map("K", vim.lsp.buf.hover, "show hover documentation")
                map("gd", vim.lsp.buf.definition, "show definitions")
                map("go", vim.lsp.buf.workspace_symbol, "workspace symbol")
                map("gl", vim.diagnostic.open_float, "open diagnostic")

                -- GLOBAL LSP MAPPING DEFAULTS, check with :h grr
            end,
        })
    end,
}
