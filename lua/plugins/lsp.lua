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
        {
            "nanotee/sqls.nvim",
            ft = "sql",
            keys = {
                {
                    "X",
                    "<Plug>(sqls-execute-query)",
                    mode = { "n", "x" },
                    ft = "sql",
                    desc = "Sqls Execute Query",
                },
            },
        },
    },

    config = function()
        -- List server capabilities
        vim.api.nvim_create_user_command("LspCapabilities", function()
            local curBuf = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_active_clients({ bufnr = curBuf })

            for _, client in pairs(clients) do
                if client.name ~= "null-ls" then
                    local capAsList = {}
                    for key, value in pairs(client.server_capabilities) do
                        if value and key:find("Provider") then
                            local capability = key:gsub("Provider$", "")
                            table.insert(capAsList, "- " .. capability)
                        end
                    end
                    table.sort(capAsList) -- sorts alphabetically
                    local msg = "# "
                        .. client.name
                        .. "\n"
                        .. table.concat(capAsList, "\n")
                    vim.notify(msg, "trace", {
                        on_open = function(win)
                            local buf = vim.api.nvim_win_get_buf(win)
                            vim.api.nvim_buf_set_option(
                                buf,
                                "filetype",
                                "markdown"
                            )
                        end,
                        timeout = 14000,
                    })
                    fn.setreg(
                        "+",
                        "Capabilities = "
                            .. vim.inspect(client.server_capabilities)
                    )
                end
            end
        end, {})

        local cmp = require("cmp")
        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ["<C-e>"] = cmp.mapping.abort(),
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
                { name = "cmdline_history", max_item_count = 3 },
                { name = "cmdline", max_item_count = 10 },
                { name = "path", max_item_count = 3 },
                { name = "buffer", max_item_count = 3 },
            }),
        })

        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "cmdline_history", max_item_count = 3 },
                { name = "buffer", max_item_count = 3 },
            }),
        })

        -- LSP
        local capabilities = vim.tbl_deep_extend(
            "force",
            vim.lsp.protocol.make_client_capabilities(),
            require("cmp_nvim_lsp").default_capabilities()
        )

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

        -- Extend capabilities to add dynamicRegistration
        local basedpyrightCapabilities =
            vim.tbl_deep_extend("force", capabilities, {
                textDocument = {
                    publishDiagnostics = {
                        tagSupport = {
                            valueSet = { 2 }, -- Fix ruff duplicate reporting
                        },
                    },
                },
                workspace = {
                    didChangeWatchedFiles = {
                        dynamicRegistration = true,
                    },
                },
            })

        vim.lsp.config("basedpyright", {
            capabilities = basedpyrightCapabilities,
            settings = {
                basedpyright = {
                    typeCheckingMode = "standard", -- off, basic, standard, strict, all
                    analysis = {
                        -- Disable some reporting in favor to ruff
                        diagnosticSeverityOverrides = {
                            reportFunctionMemberAccess = false,
                            reportMissingImports = false,
                            reportMissingModuleSource = false,
                            reportImportCycles = false,
                            reportUnusedImport = false,
                            reportUnusedClass = false,
                            reportUnusedFunction = false,
                            reportUnusedVariable = false,
                            reportDuplicateImport = false,
                            reportWildcardImportFromLibrary = false,
                            reportAbstractUsage = false,
                            reportAttributeAccessIssue = false,
                            reportCallIssue = false,
                            reportInconsistentOverload = false,
                            reportIndexIssue = false,
                            reportNoOverloadImplementation = false,
                            reportOperatorIssue = false,
                            reportOptionalSubscript = false,
                            reportOptionalMemberAccess = false,
                            reportOptionalCall = false,
                            reportOptionalIterable = false,
                            reportOptionalContextManager = false,
                            reportOptionalOperand = false,
                            reportRedeclaration = false,
                            reportPrivateUsage = false,
                            reportPrivateImportUsage = false,
                            reportConstantRedefinition = false,
                            reportDeprecated = false,
                            reportIncompatibleMethodOverride = false,
                            reportIncompatibleVariableOverride = false,
                            reportInconsistentConstructor = false,
                            reportOverlappingOverload = false,
                            reportPossiblyUnboundVariable = false,
                            reportMissingSuperCall = false,
                            reportUninitializedInstanceVariable = false,
                            reportInvalidStringEscapeSequence = false,
                            reportCallInDefaultInitializer = false,
                            reportUnnecessaryIsInstance = false,
                            reportUnnecessaryCast = false,
                            reportUnnecessaryComparison = false,
                            reportUnnecessaryContains = false,
                            reportAssertAlwaysTrue = false,
                            reportSelfClsParameterName = false,
                            reportImplicitStringConcatenation = false,
                            reportUndefinedVariable = false,
                            reportUnboundVariable = false,
                            reportUnhashable = false,
                            reportUnsupportedDunderAll = false,
                            reportUnusedCallResult = false,
                            reportUnusedCoroutine = false,
                            reportUnusedExcept = false,
                            reportUnusedExpression = false,
                            reportMatchNotExhaustive = false,
                            reportImplicitOverride = false,
                            reportShadowedImports = false,
                        },
                        inlayHints = {
                            callArgumentNames = false,
                        },
                    },
                    -- Disable, since I use ruff
                    disableOrganizeImports = true,
                },
            },
        })
        vim.lsp.enable("basedpyright")

        vim.lsp.config("pylsp", {
            capabilities = capabilities,
            on_attach = function(client)
                -- Disable capabilities in favor to basedpyright
                local disabled_capabilities = {
                    "documentFormattingProvider",
                    "documentHighlightProvider",
                    "foldingRangeProvider",
                    "codeLensProvider",
                    "typeDefinitionProvider",
                    "documentSymbolProvider",
                    "renameProvider",
                    "hoverProvider",
                    "signatureHelpProvider",
                    "definitionProvider",
                    "referencesProvider",
                    "completionProvider",
                    "documentRangeFormattingProvider",
                    "semanticTokensProvider",
                    "inlayHintProvider",
                }
                for _, cap in ipairs(disabled_capabilities) do
                    client.server_capabilities[cap] = false
                end
            end,
            settings = {
                -- Disable features in favor to basedpyright
                pylsp = {
                    disableDiagnostics = true,
                    plugins = {
                        autopep8 = { enabled = false },
                        jedi_completion = { enabled = false },
                        jedi_definition = { enabled = false },
                        jedi_hover = { enabled = false },
                        jedi_references = { enabled = false },
                        jedi_signature_help = { enabled = false },
                        jedi_symbols = { enabled = false },
                        jedi_type_definition = { enabled = false },
                        mccabe = { enabled = false },
                        preload = { enabled = false },
                        pycodestyle = { enabled = false },
                        pyflakes = { enabled = false },
                        yapf = { enabled = false },
                    },
                },
            },
        })
        vim.lsp.enable("pylsp")

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
                "php",
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
                            snippetSupport = true,
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
                            snippetSupport = true,
                        },
                    },
                },
            }),
            filetypes = { "html", "templ", "smarty", "jinja" },
        })
        vim.lsp.enable("html")

        vim.lsp.config("sqls", {
            capabilities = capabilities,
            cmd = { "sqls", "-config", "/home/inom/.config/sqls/config.yml" },
        })
        vim.lsp.enable("sqls")

        -- Configure diagnostic
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
                map("K", function()
                    local base_win_id = vim.api.nvim_get_current_win()
                    local windows = vim.api.nvim_tabpage_list_wins(0)
                    for _, win_id in ipairs(windows) do
                        if win_id ~= base_win_id then
                            local win_cfg = vim.api.nvim_win_get_config(win_id)
                            if win_cfg.relative == "win" and win_cfg.win == base_win_id then
                                vim.api.nvim_win_close(win_id, {})
                                return
                            end
                        end
                    end
                    vim.lsp.buf.hover()
                end, "toggle hover")

                map("gd", vim.lsp.buf.definition, "show definitions")
                map("go", vim.lsp.buf.workspace_symbol, "workspace symbol")
                map("gl", vim.diagnostic.open_float, "open diagnostic")

                -- GLOBAL LSP MAPPING DEFAULTS, check with :h grr
            end,
        })
    end,
}
