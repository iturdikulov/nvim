--[[
  setup is based on this blogpost:
  https://vonheikemen.github.io/devlog/tools/setup-nvim-lspconfig-plus-nvim-cmp/
]]
-- Test plugins exists
local plugins = { "lspconfig", "cmp", "cmp_nvim_lsp", "luasnip"}

for _, plugin in ipairs(plugins) do
    local ok, _ = pcall(require, plugin)
    if not ok then
        return
    end
end

---
-- Reduce floating window size
---
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "single"
    opts.max_width = opts.max_width or 80
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

---
-- Keybindings
---
vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP actions",
    callback = function(event)
        local map = function(lhs, rhs, desc)
            if desc then
                desc = "[LSP] " .. desc
            end

            vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
        end

        map("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
        map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
        map("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "List workspace folders")

        map("K", vim.lsp.buf.hover, "hover")
        -- NOTE: this keymap for xst/st term, in our case Ctrl-F1
        vim.keymap.set({ "i", "n" }, "<F25>", function()
            vim.lsp.buf.signature_help()
        end, { desc = "[LSP] signature Help" })

        map("gd", vim.lsp.buf.definition, "go to definition")
        map("gD", vim.lsp.buf.declaration, "go to declaration")
        map("gI", vim.lsp.buf.implementation, "go to implementation")

        map("go", vim.lsp.buf.type_definition, "go to type definition")
        map("gr", vim.lsp.buf.references, "go to references")
        map("<leader>vrn", vim.lsp.buf.rename, "rename")
        map("<leader>vaa", vim.lsp.buf.code_action, "code action")
        vim.keymap.set("x", "<leader>vaa", function()
            vim.lsp.buf.range_code_action()
        end, { silent = true, desc = "[LSP] Range Code Action" })

        -- Diagnostic
        map("gq", vim.diagnostic.setloclist, "open diagnostics list")
        map("gl", vim.diagnostic.open_float, "hover diagnostic")
        map("[d", vim.diagnostic.goto_prev, "go to previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "go to next diagnostic")

        -- Symbols
        map("<leader>vws", function()
            vim.cmd("Telescope lsp_dynamic_workspace_symbols")
        end, "telescope workspace symbol")

        map("<leader>vwS", vim.lsp.buf.workspace_symbol, "workspace Symbol")

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})

---
-- Diagnostics
---

local sign = function(opts)
    vim.fn.sign_define(opts.name, { texthl = opts.name, text = opts.text, numhl = "" })
end

sign({ name = "DiagnosticSignError", text = "E" })
sign({ name = "DiagnosticSignWarn", text = "W" })
sign({ name = "DiagnosticSignHint", text = "?" })
sign({ name = "DiagnosticSignInfo", text = "I" })

vim.diagnostic.config({
    severity_sort = true,
    float = { border = "rounded", source = "always" },
    virtual_text = {
        severity = { min = vim.diagnostic.severity.WARN },
    },
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

---
-- LSP config
---

local lspconfig = require("lspconfig")
local lsp_defaults = lspconfig.util.default_config

-- Update default capabilities
lsp_defaults.capabilities = vim.tbl_deep_extend(
    "force",
    lsp_defaults.capabilities,
    require("cmp_nvim_lsp").default_capabilities()
)

---
-- LSP servers
---
local function on_attach(client, bufnr)
    local augroup = vim.api.nvim_create_augroup
    if vim.env.NVIM_AUTOFORMAT == "1" and client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format()
            end,
        })
    end

    if client.server_capabilities.inlayHintProvider then
      -- Inline hints on isert
      vim.api.nvim_create_augroup("lsp_augroup", { clear = true })

      vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = bufnr,
        callback = function() vim.lsp.inlay_hint.enable(true, {bufnr=bufnr}) end,
        group = "lsp_augroup",
      })
      vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = bufnr,
        callback = function() vim.lsp.inlay_hint.enable(false, {bufnr=bufnr}) end,
        group = "lsp_augroup",
      })
    end
end


lspconfig.biome.setup({
  single_file_support = true,
  filetypes = { "javascript", "javascriptreact", "json",
                "jsonc", "typescript", "typescript.tsx",
                "typescriptreact", "astro", "svelte",
                "vue", "css" }
})
lspconfig.nil_ls.setup{}
lspconfig.ts_ls.setup {}
lspconfig.gopls.setup {}
lspconfig.cssls.setup {}
lspconfig.texlab.setup {}
lspconfig.marksman.setup {}
lspconfig.arduino_language_server.setup {}
lspconfig.lua_ls.setup({
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = "LuaJIT",
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { "vim" },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = { enable = false },
        },
    },
})
lspconfig.ruff.setup({ on_attach = on_attach })
lspconfig.basedpyright.setup({
    on_attach = on_attach,
    settings = {
        basedpyright = {
            analysis = {
                diagnosticMode = "openFilesOnly",  -- "workspace" or "openFilesOnly"
            }
        }
    }
})
lspconfig.clangd.setup({ on_attach = on_attach })
lspconfig.rust_analyzer.setup({ on_attach = on_attach })
lspconfig.gdscript.setup({})
lspconfig.emmet_ls.setup({
    filetypes = { "html", "typescript", "typescriptreact", "jinja", "css", "scss" },
})

-- NEXT: replace with something better?
local ok, ltex_extra = pcall(require, "ltex_extra")
if ok then
    lspconfig.ltex.setup({
        on_attach = function(_, bufnr)
            -- Skip if buffer read-only
            if vim.api.nvim_buf_get_option(bufnr, "ro") then
                return
            end

            ltex_extra.setup({
                load_langs = { "ru-RU", "en-US", "fr" },     -- table <string> : languages for witch dictionaries will be loaded
                init_check = true,                           -- boolean : whether to load dictionaries on startup
                path = vim.fn.stdpath("config") .. "/spell", -- string : path to store dictionaries. Relative path uses current working directory
                log_level = "warn",                          -- string : "none", "trace", "debug", "info", "warn", "error", "fatal"
            })
        end,
        filetypes = { "gitcommit", "mail", "text", "tex", "markdown" },
    })
end

local cmp = require("cmp")
local luasnip = require("luasnip")
local max_item_count = 12

local select_opts = { behavior = cmp.SelectBehavior.Select }
cmp.setup.filetype({ "sql", "mysql" }, {
    sources = {
        { name = "vim-dadbod-completion"},
        { name = "buffer"},
    }
})
cmp.setup({
    max_item_count = max_item_count,
    sources = {
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "luasnip" },
        { name = "buffer" },
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    window = { documentation = cmp.config.window.bordered() },
    formatting = {
        fields = { "menu", "abbr", "kind" },
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = ">",
                luasnip = "[s]",
                buffer = "[b]",
                path = "[/]",
                supermaven = "[c]",
            }

            item.menu = menu_icon[entry.source.name]
            item.abbr = string.sub(item.abbr, 1, 80)
            return item
        end,
    },

    mapping = {
        ["<Tab>"] = vim.NIL,
        ["<S-Tab>"] = vim.NIL,
        ["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
        ["<C-n>"] = cmp.mapping.select_next_item(select_opts),

        ["<PageUp>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select, count = 10 }),
        ["<PageDown>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select, count = 10 }),

        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),

        ["<C-space>"] = cmp.mapping.complete(),
        ["<C-y>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({select = true});
          elseif luasnip.expandable() then
            luasnip.expand()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-c>"] = cmp.mapping.abort(),
    },
})
