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
			"mason-org/mason-lspconfig.nvim",
			dependencies = {
				{ "mason-org/mason.nvim", opts = {} },
				"neovim/nvim-lspconfig",
			},
			opts = {
				automatic_enable = false,
				ensure_installed = {
					"lua_ls",
					"stylua",
                    "basedpyright",
					"vue_ls",
					"pylsp",
					"cssls",
					"ruff",
					"biome",
					"vtsls",
					"ts_ls",
				},
			},
		},
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
		-- Install non-lsp mason packages
		local my_packages = "goimports deno djlint shfmt sqlfluff tex-fmt js-debug-adapter"
		vim.keymap.set('n', '<leader>mi', ':MasonInstall ' .. my_packages .. '<CR>', {
			desc = '[M]ason [I]nstall packages',
			silent = true
		})

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
					local msg = "# " .. client.name .. "\n" .. table.concat(capAsList, "\n")
					vim.notify(msg, "trace", {
						on_open = function(win)
							local buf = vim.api.nvim_win_get_buf(win)
							vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
						end,
						timeout = 14000,
					})
					fn.setreg("+", "Capabilities = " .. vim.inspect(client.server_capabilities))
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
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
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
				{
					name = "spell",
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
			"dockerls",
			"yamlls",
		}

		for _, lsp in ipairs(base_config_lsp) do
			vim.lsp.config(lsp, {
				capabilities = capabilities,
			})
			vim.lsp.enable(lsp)
		end

		local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'
		local tsserver_filetypes = {
			"typescript",
			"javascript",
			"javascriptreact",
			"typescriptreact",
			"vue"
		}
		local vue_plugin = {
			name = "@vue/typescript-plugin",
			location = vue_language_server_path,
			languages = { "vue" },
			configNamespace = "typescript",
		}

		local vtsls_config = {
            capabilities = capabilities,
			settings = {
				vtsls = {
					tsserver = {
						globalPlugins = {
							vue_plugin,
						},
					},
				},
			},
			filetypes = tsserver_filetypes,
		}

		local ts_ls_config = {
            capabilities = capabilities,
			init_options = {
				plugins = {
					vue_plugin,
				},
			},
			filetypes = tsserver_filetypes,
		}

		-- If you are on most recent `nvim-lspconfig`
        local vue_ls_config = {
            capabilities = capabilities,
		}
		vim.lsp.config("vtsls", vtsls_config)
		vim.lsp.config("vue_ls", vue_ls_config)
		vim.lsp.config("ts_ls", ts_ls_config)
		vim.lsp.enable({ "vtsls", "vue_ls" }) -- If using `ts_ls` replace `vtsls` to `ts_ls`

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
		local basedpyrightCapabilities = vim.tbl_deep_extend("force", capabilities, {
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

					vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
				end

				map("K", function()
					vim.lsp.buf.hover {
						border = "single",
						max_height = 25,
						max_width = 130,
						close_events = { "CursorMoved", "LSPDetach" },
					}
				end)

				map("gd", vim.lsp.buf.definition, "show definitions")
				map("go", vim.lsp.buf.workspace_symbol, "workspace symbol")
				map("gl", vim.diagnostic.open_float, "open diagnostic")

				-- GLOBAL LSP MAPPING DEFAULTS, check with :h grr
			end,
		})
	end,
}
