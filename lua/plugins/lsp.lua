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
			"jedrzejboczar/devcontainers.nvim",
			enabled = not require("config.platform").is_windows,
			dependencies = { "miversen33/netman.nvim" },
			config = function()
				require("devcontainers").setup()
				require("config.container_lsp").setup_cli_override()

				local status = require("config.lsp_status")

				local cli = require("devcontainers.cli")
				local devcontainer_up = cli.devcontainer_up
				cli.devcontainer_up = function(...)
					local args = { ... }
					local notify = vim.notify
					status.inc()
					vim.notify = function(message, level, opts)
						if message:match("^Starting devcontainer") and not message:match(": FAILED:") then
							return {}
						end
						return notify(message, level, opts)
					end

					local ok, result = xpcall(function()
						return devcontainer_up(unpack(args))
					end, debug.traceback)
					vim.notify = notify
					status.dec()
					if not ok then
						error(result)
					end
					return result
				end
			end,
		},
		{
			"mason-org/mason-lspconfig.nvim",
			dependencies = {
				{ "mason-org/mason.nvim", opts = {} },
				"neovim/nvim-lspconfig",
			},
			opts = (function()
				local ensure_installed = {
					"copilot",
					"lua_ls",
					"stylua",
					"powershell_es",
					"basedpyright",
					"ansiblels",
					"vue_ls",
					"emmet_language_server",
					"pylsp",
					"cssls",
					"ruff",
					"vtsls",
					"ts_ls",
					-- "gopls",
					-- "sqls",
					"rust_analyzer",
					"bashls",
					"markdown_oxide",
					"texlab",
					"jsonls",
					"html",
					"yamlls",
					"dockerls",
					"clangd",
				}
				if not require("config.platform").is_windows then
					table.insert(ensure_installed, "asm_lsp")
				end
				return {
					automatic_enable = false,
					ensure_installed = ensure_installed,
				}
			end)(),
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
		require("config.lsp_status").setup()

		-- Install non-lsp mason packages
		local my_packages = {
			-- Go
			"goimports",

			-- Shell
			"shellcheck",
			"shfmt",

			-- SQL
			"sqlfluff",

			-- Python
			"mypy",
			"djlint",
			"pylint",
			"debugpy",

			-- Markdown / Docs / LaTeX
			"tex-fmt",

			-- Web / Node ecosystem
			"js-debug-adapter",
		}


		local PYLSP_ROPE = "pylsp-rope==0.1.17"

		local function mason_pylsp_venv_bin(name)
			return vim.fs.joinpath(vim.fn.stdpath("data"), "mason/packages/python-lsp-server/venv/bin", name)
		end

		local function pylsp_rope_installed()
			local python = mason_pylsp_venv_bin("python")
			if vim.fn.executable(python) ~= 1 then
				return false
			end
			vim.fn.system({ python, "-c", "import importlib.metadata as m; m.version('pylsp-rope')" })
			return vim.v.shell_error == 0
		end

		local pylsp_rope_job ---@type integer|nil

		local function ensure_pylsp_rope(force)
			if not force and pylsp_rope_installed() then
				return
			end
			local pip = mason_pylsp_venv_bin("pip")
			if vim.fn.executable(pip) ~= 1 then
				if force then
					vim.notify("Mason python-lsp-server venv not found", vim.log.levels.ERROR)
				end
				return
			end
			if pylsp_rope_job and vim.fn.jobwait({ pylsp_rope_job }, 0)[1] == -1 then
				return
			end
			pylsp_rope_job = vim.fn.jobstart({ pip, "install", PYLSP_ROPE }, {
				on_exit = function(_, code)
					pylsp_rope_job = nil
					if force or code ~= 0 then
						vim.notify(
							code == 0 and "pylsp-rope installed" or "pylsp-rope install failed",
							code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
						)
					end
				end,
			})
		end

		vim.keymap.set('n', '<leader>mi', function()
			-- Join the table items into a single space-separated string
			local packages_str = table.concat(my_packages, " ")
			vim.cmd("MasonInstall " .. packages_str)
		end, {
			desc = '[M]ason [I]nstall packages',
			silent = true
		})

		vim.keymap.set("n", "<leader>mp", function()
			ensure_pylsp_rope(true)
		end, {
			desc = "[M]ason [P]ylsp-rope install",
			silent = true,
		})

		local ok_registry, registry = pcall(require, "mason-registry")
		if ok_registry then
			registry:on("package:install:success", function(pkg)
				if pkg.name == "python-lsp-server" then
					vim.schedule(ensure_pylsp_rope)
				end
			end)
		end
		vim.schedule(ensure_pylsp_rope)

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

		local function show_lsp_commands()
			local lines = {}
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				local devcontainers = client.config._devcontainers or {}
				table.insert(lines, ("# %s"):format(client.name))
				table.insert(lines, ("root: %s"):format(client.config.root_dir or "?"))
				table.insert(lines, ("cmd: %s"):format(vim.inspect(devcontainers.cmd or client.config.cmd)))
				if devcontainers.original_cmd then
					table.insert(lines, ("original: %s"):format(vim.inspect(devcontainers.original_cmd)))
				end
			end
			if #lines == 0 then
				lines = { "No LSP clients attached to the current buffer" }
			end
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { timeout = 14000 })
		end

		vim.keymap.set("n", "<leader>Li", show_lsp_commands, {
			desc = "Show LSP commands",
			silent = true,
		})

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
					entry_filter = require("config.spell").cmp_entry_filter,
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

		if not vim.g.lsp_strip_svg_images then
			local convert_markdown = vim.lsp.util.convert_input_to_markdown_lines
			vim.lsp.util.convert_input_to_markdown_lines = function(contents, ...)
				local lines = convert_markdown(contents, ...)
				for index, line in ipairs(lines) do
					lines[index] = line:gsub("!%[[^%]]*%]%([^)]*[Ss][Vv][Gg][^)]*%)", "")
				end
				return lines
			end
			vim.g.lsp_strip_svg_images = true
		end

		-- LSP
		local capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("cmp_nvim_lsp").default_capabilities()
		)
		local is_windows = require("config.platform").is_windows
		local has_devcontainers = (not is_windows) and pcall(require, "devcontainers")
		local container_lsp = has_devcontainers and require("config.container_lsp") or nil
		local lsp_status = require("config.lsp_status")
		local container_workspace = require("config.container_workspace")
		local register_capability = vim.lsp.handlers["client/registerCapability"]

		-- TODO: Remove when devcontainers.nvim handles container-only watcher baseUri values.
		local function register_container_capability(err, params, ctx, config)
			local client = vim.lsp.get_client_by_id(ctx.client_id)
			local root_dir = client and client.config.root_dir
			if root_dir and container_workspace.has_devcontainer_ancestor(root_dir) then
				params = vim.deepcopy(params)
				for _, registration in ipairs(params.registrations or {}) do
					if registration.method == "workspace/didChangeWatchedFiles" then
						local options = registration.registerOptions or {}
						options.watchers = vim.tbl_filter(function(watcher)
							local pattern = watcher.globPattern
							local base_uri = type(pattern) == "table" and pattern.baseUri or nil
							base_uri = type(base_uri) == "table" and base_uri.uri or base_uri
							return type(base_uri) ~= "string"
								or not base_uri:match("^file:")
								or vim.uv.fs_stat(vim.uri_to_fname(base_uri)) ~= nil
						end, options.watchers or {})
						registration.registerOptions = options
					end
				end
			end
			return register_capability(err, params, ctx, config)
		end

		local function configure_container_lsp(name, config)
			local default_config = vim.lsp.config[name]
			local default_root_dir = default_config.root_dir
			local default_root_markers = default_config.root_markers
			config = config or {}
			local project_root_markers = config.project_root_markers
			config.project_root_markers = nil
			local container_cmd = container_lsp
					and container_lsp.lsp_cmd(config.container_cmd or default_config.cmd, {
						before_start = function()
							lsp_status.inc()
						end,
					})
				or nil
			config.container_cmd = nil
			config.cmd = function(dispatchers, client_config)
				local root_dir = client_config.root_dir and vim.fs.normalize(client_config.root_dir)
				if container_cmd and container_workspace.is_under_workspace(root_dir) then
					return container_cmd(dispatchers, client_config)
				end
				local cmd = config.cmd_local or default_config.cmd
				if type(cmd) == "function" then
					return cmd(dispatchers, client_config)
				end
				return vim.lsp.rpc.start(cmd, dispatchers)
			end
			config.cmd_local = nil
			config.handlers = vim.tbl_extend("force", config.handlers or {}, {
				["client/registerCapability"] = register_container_capability,
			})
			config.root_dir = function(bufnr, on_dir)
				-- Внутри monorepo с маркером `az` — только packages/*, не корень репо.
				if container_workspace.workspace_root(bufnr) then
					on_dir(container_workspace.find_project_root(bufnr, project_root_markers))
					return
				end

				if type(default_root_dir) == "function" then
					return default_root_dir(bufnr, on_dir)
				end
				if default_root_markers then
					on_dir(vim.fs.root(bufnr, default_root_markers))
					return
				end
				if default_root_dir then
					on_dir(default_root_dir)
					return
				end
				on_dir(nil)
			end
			vim.lsp.config(name, config)
		end

		local base_config_lsp = {
			"clangd",
			"gdscript",
			"gopls",
			"dockerls",
		}
		if not is_windows then
			table.insert(base_config_lsp, "asm_lsp")
		end

		for _, lsp in ipairs(base_config_lsp) do
			vim.lsp.config(lsp, {
				capabilities = capabilities,
			})
			vim.lsp.enable(lsp)
		end

		vim.lsp.config("ansiblels", {
			capabilities = capabilities,
			filetypes = { "yaml", "yaml.ansible" },
			root_dir = function(bufnr, on_dir)
				on_dir(vim.fs.root(bufnr, { "ansible.cfg", ".ansible-lint" }))
			end,
			before_init = function(_, config)
				local root = config.root_dir
				local venv = root and vim.fs.joinpath(root, ".venv") or nil
				local bin_dir = is_windows and "Scripts" or "bin"
				if not venv or vim.fn.executable(vim.fs.joinpath(venv, bin_dir, "python")) ~= 1 then
					return
				end
				config.settings.ansible.python.interpreterPath = vim.fs.joinpath(venv, bin_dir, "python")
				config.settings.ansible.ansible.path = vim.fs.joinpath(venv, bin_dir, "ansible")
				config.settings.ansible.validation.lint.path = vim.fs.joinpath(venv, bin_dir, "ansible-lint")
			end,
			settings = {
				ansible = {
					python = {
						interpreterPath = "python",
					},
					ansible = {
						path = "ansible",
					},
					validation = {
						lint = {
							path = "ansible-lint",
						},
					},
				},
			},
		})
		vim.lsp.enable("ansiblels")

		-- JS/TS/Vue lint: nvim-lint + eslint_d (host); format: conform + prettier
		local container_base_lsp = {
			{ name = "bashls" },
			{ name = "yamlls", cmd = { "yaml-language-server", "--stdio" } },
			{ name = "jsonls", cmd = { "vscode-json-language-server", "--stdio" } },
		}

		for _, server in ipairs(container_base_lsp) do
			configure_container_lsp(server.name, {
				capabilities = capabilities,
				container_cmd = server.cmd,
				filetypes = server.filetypes,
			})
			vim.lsp.enable(server.name)
		end

		-- Vue / vtsls — https://github.com/vuejs/language-tools/wiki/Neovim
		local local_vue_language_server_path = vim.fn.stdpath("data")
			.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

		local CONTAINER_VUE_LS = "/usr/local/lib/node_modules/@vue/language-server"
		local CONTAINER_TSDK = "/usr/local/lib/node_modules/typescript/lib"

		local function uses_devcontainer_lsp(root)
			return root
				and container_workspace.is_under_workspace(root)
				and container_workspace.has_devcontainer_ancestor(root)
				and container_workspace.container_kind(root) == "frontend"
		end

		local function resolve_vue_language_server_path(root)
			if uses_devcontainer_lsp(root) then
				return CONTAINER_VUE_LS
			end
			root = root and vim.fs.normalize(root)
			local candidates = {
				root and (root .. "/node_modules/@vue/language-server"),
				local_vue_language_server_path,
			}
			for _, path in ipairs(candidates) do
				if path and vim.uv.fs_stat(path) then
					return path
				end
			end
			return local_vue_language_server_path
		end

		local function resolve_typescript_tsdk(root)
			if uses_devcontainer_lsp(root) then
				return CONTAINER_TSDK
			end
			if not root then
				return nil
			end
			local lib = vim.fs.normalize(root) .. "/node_modules/typescript/lib"
			if vim.uv.fs_stat(lib) then
				return lib
			end
			local mason_tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript/lib"
			if vim.uv.fs_stat(mason_tsdk) then
				return mason_tsdk
			end
			return nil
		end

		local tsserver_filetypes = {
			"typescript",
			"javascript",
			"javascriptreact",
			"typescriptreact",
			"vue",
		}
		local js_only_filetypes = {
			"javascript",
			"javascriptreact",
			"vue",
		}

		local function is_js_only_project(root)
			return root and vim.uv.fs_stat(root .. "/tsconfig.json") == nil
		end

		--- JS-only: ts-plugin варнинги off, плагин остаётся для gD/K через vue_ls.
		local function attach_js_only_ts_plugin_filter(client)
			local root = client.config.root_dir
			if not is_js_only_project(root) or client._js_only_ts_plugin_filter then
				return
			end
			client._js_only_ts_plugin_filter = true
			local publish = vim.lsp.handlers["textDocument/publishDiagnostics"]
			client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, ...)
				local bufnr = ctx and ctx.bufnr
				if
					type(bufnr) ~= "number"
					or bufnr <= 0
					or not vim.api.nvim_buf_is_valid(bufnr)
					or vim.bo[bufnr].filetype ~= "vue"
					or not result
					or not result.diagnostics
				then
					return publish(err, result, ctx, ...)
				end
				result.diagnostics = vim.tbl_filter(function(d)
					if d.source ~= "ts-plugin" then
						return true
					end
					local sev = d.severity or vim.diagnostic.severity.WARN
					return sev <= vim.diagnostic.severity.ERROR
				end, result.diagnostics)
				if #result.diagnostics == 0 then
					vim.diagnostic.reset(vim.lsp.diagnostic.get_namespace(client.id), bufnr)
					return
				end
				return publish(err, result, ctx, ...)
			end
		end

		local function make_vue_plugin(root)
			return {
				name = "@vue/typescript-plugin",
				location = resolve_vue_language_server_path(root),
				languages = { "vue" },
				configNamespace = "typescript",
				enableForWorkspaceTypeScriptVersions = true,
			}
		end

		local vtsls_config = {
			capabilities = capabilities,
			project_root_markers = { "package.json" },
			before_init = function(_, config)
				local root = config.root_dir
				config.settings.vtsls.tsserver.globalPlugins = { make_vue_plugin(root) }
				local tsdk = resolve_typescript_tsdk(root)
				if tsdk then
					config.settings.typescript = vim.tbl_deep_extend("force", config.settings.typescript or {}, {
						tsdk = tsdk,
					})
				end
				if is_js_only_project(root) then
					config.filetypes = js_only_filetypes
					config.settings.javascript = vim.tbl_deep_extend(
						"force",
						config.settings.javascript or {},
						{
							validate = { enable = true },
							implicitProjectConfig = { checkJs = true },
						}
					)
					-- ts-plugin в .vue идёт через namespace typescript — без validate, но plugin жив
					config.settings.typescript = vim.tbl_deep_extend(
						"force",
						config.settings.typescript or {},
						{
							validate = { enable = false },
						}
					)
				end
			end,
			settings = {
				vtsls = {
					tsserver = {
						globalPlugins = {},
					},
				},
			},
			filetypes = tsserver_filetypes,
			on_attach = function(client, bufnr)
				attach_js_only_ts_plugin_filter(client)
				local caps = client.server_capabilities
				if not caps.semanticTokensProvider then
					return
				end
				if vim.bo[bufnr].filetype == "vue" then
					caps.semanticTokensProvider.full = false
				else
					caps.semanticTokensProvider.full = true
				end
			end,
		}

		-- on_init для tsserver/request — из nvim-lspconfig/lsp/vue_ls.lua
		local vue_ls_config = {
			capabilities = capabilities,
			project_root_markers = { "package.json" },
			on_attach = function(client, bufnr)
				attach_js_only_ts_plugin_filter(client)
				if vim.bo[bufnr].filetype == "vue" and client.server_capabilities.semanticTokensProvider then
					client.server_capabilities.semanticTokensProvider.full = true
				end
			end,
		}

		vim.api.nvim_set_hl(0, "@lsp.type.component", { link = "@type" })

		configure_container_lsp("vtsls", vtsls_config)
		configure_container_lsp("vue_ls", vue_ls_config)
		vim.lsp.enable({ "vue_ls", "vtsls" })

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

		configure_container_lsp("basedpyright", {
			capabilities = basedpyrightCapabilities,
			project_root_markers = { "pyproject.toml", "requirements.txt" },
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

		configure_container_lsp("pylsp", {
			capabilities = capabilities,
			project_root_markers = { "pyproject.toml", "requirements.txt" },
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
						jedi_rename = { enabled = false },
						jedi_signature_help = { enabled = false },
						jedi_symbols = { enabled = false },
						jedi_type_definition = { enabled = false },
						mccabe = { enabled = false },
						preload = { enabled = false },
						pycodestyle = { enabled = false },
						pyflakes = { enabled = false },
						pylsp_rope = {
							rename = { enabled = false },
						},
						yapf = { enabled = false },
					},
				},
			},
		})
		vim.lsp.enable("pylsp")

		configure_container_lsp("ruff", {
			capabilities = capabilities,
			project_root_markers = { "pyproject.toml", "requirements.txt" },
		})
		vim.lsp.enable("ruff")

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

		vim.lsp.config("powershell_es", {
			capabilities = capabilities,
			bundle_path = vim.fn.expand("$MASON/packages/powershell-editor-services"),
			shell = "pwsh",
			settings = {
				powershell = {
					scriptAnalysis = {
						enable = true,
						settingsPath = vim.fs.joinpath(
							vim.fn.stdpath("config"),
							"powershell",
							"PSScriptAnalyzerSettings.psd1"
						),
					},
				},
			},
		})
		vim.lsp.enable("powershell_es")

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
			cmd = {
				"sqls",
				"-config",
				vim.fs.joinpath(vim.fn.stdpath("config"), "sqls", "config.yml"),
			},
		})
		vim.lsp.enable("sqls")

		vim.lsp.enable("copilot")

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
				local client = vim.lsp.get_client_by_id(e.data.client_id)
				if client and client.name == "copilot" then
					if client:supports_method("textDocument/inlineCompletion", e.buf) then
						vim.lsp.inline_completion.enable(true, { bufnr = e.buf })
					end
				end

				local map = function(lhs, rhs, desc)
					if desc then
						desc = "[LSP] " .. desc
					end

					vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
				end

				map("K", function()
					vim.lsp.buf.hover({ border = "single", max_width = 80 })
				end, "show hover")

				map("gd", vim.lsp.buf.definition, "show definitions")
				map("go", vim.lsp.buf.workspace_symbol, "workspace symbol")
				map("gl", vim.diagnostic.open_float, "open diagnostic")

				-- GLOBAL LSP MAPPING DEFAULTS, check with :h grr
			end,
		})
	end,
}
