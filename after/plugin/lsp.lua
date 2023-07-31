--[[
  blogpost:
  https://vonheikemen.github.io/devlog/tools/setup-nvim-lspconfig-plus-nvim-cmp/

  Dependencies:
  LSP:
  https://github.com/neovim/nvim-lspconfig
  https://github.com/williamboman/mason.nvim             (optional)
  https://github.com/williamboman/mason-lspconfig.nvim   (optional)

  Completion:
  https://github.com/hrsh7th/nvim-cmp
  https://github.com/hrsh7th/cmp-nvim-lsp
  https://github.com/hrsh7th/cmp-buffer
  https://github.com/hrsh7th/cmp-path
  https://github.com/saadparwaiz1/cmp_luasnip

  Snippets:
  https://github.com/L3MON4D3/LuaSnip
  https://github.com/rafamadriz/friendly-snippets
]] -- Test plugins exists
local plugins = {"lspconfig", "cmp", "cmp_nvim_lsp", "luasnip", "copilot_cmp"}

for id, plugin in ipairs(plugins) do
    local ok, loaded_plug = pcall(require, plugin)
    if not ok then return end
end

---
-- Keybindings
---

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function()
        local map = function(lhs, rhs, desc)
            if desc then desc = "[LSP] " .. desc end

            vim.keymap.set("n", lhs, rhs, {silent = true, desc = desc})
        end

        map('<leader>wa', vim.lsp.buf.add_workspace_folder,
            "Add workspace folder")
        map('<leader>wr', vim.lsp.buf.remove_workspace_folder,
            "Remove workspace folder")
        map('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "Lis workspace folders")

        map("K", vim.lsp.buf.hover, "hover")
        map("gd", vim.lsp.buf.definition, 'go to definition')
        map("gD", vim.lsp.buf.declaration, 'go to declaration')
        map("gi", vim.lsp.buf.implementation, 'go to implementation')

        -- Formatting
        map("<leader>F", function() vim.lsp.buf.format {async = true} end,
            'format')
        vim.keymap.set("v", "<leader>F",
                       function() vim.lsp.buf.format {async = true} end,
                       {silent = true, desc = "LSP Visual Format"})

        map('go', vim.lsp.buf.type_definition, "go to type definition")
        map('gr', vim.lsp.buf.references, "go to references")
        vim.keymap.set("i", "<C-h>",
                       function() vim.lsp.buf.signature_help() end,
                       {desc = '[LSP] signature Help'})

        map('<leader>vrn', vim.lsp.buf.rename, "rename")
        map("<leader>vaa", vim.lsp.buf.code_action, 'code action')
        vim.keymap.set("x", "<leader>vaa",
                       function() vim.lsp.buf.range_code_action() end,
                       {silent = true, desc = "[LSP] Range Code Action"})

        -- Diagnostic
        map('gl', vim.diagnostic.open_float, "open diagnostic")
        map("[d", vim.diagnostic.goto_prev, 'go to previous diagnostic')
        map("]d", vim.diagnostic.goto_next, 'go to next diagnostic')

        -- Symbols
        map("<leader>vws",
            function() vim.cmd("Telescope lsp_dynamic_workspace_symbols") end,
            'telescope workspace symbol')

        map("<leader>vwS", vim.lsp.buf.workspace_symbol, 'workspace Symbol')
    end
})

---
-- Diagnostics
---

local sign = function(opts)
    vim.fn.sign_define(opts.name,
                       {texthl = opts.name, text = opts.text, numhl = ''})
end

sign({name = 'DiagnosticSignError', text = '✘'})
sign({name = 'DiagnosticSignWarn', text = '▲'})
sign({name = 'DiagnosticSignHint', text = '󰈻'})
sign({name = 'DiagnosticSignInfo', text = ''})
sign({name = 'CmpItemKindCopilot', text = ''})

vim.diagnostic.config({
    virtual_text = false,
    severity_sort = true,
    float = {border = 'rounded', source = 'always'}
})

vim.lsp.handlers['textDocument/hover'] =
    vim.lsp.with(vim.lsp.handlers.hover, {border = 'rounded'})

vim.lsp.handlers['textDocument/signatureHelp'] =
    vim.lsp.with(vim.lsp.handlers.signature_help, {border = 'rounded'})

---
-- LSP config
---

-- require('mason').setup({})
-- require('mason-lspconfig').setup({})

require("copilot_cmp").setup()

local lspconfig = require('lspconfig')
local lsp_defaults = lspconfig.util.default_config

lsp_defaults.capabilities = vim.tbl_deep_extend('force',
                                                lsp_defaults.capabilities,
                                                require('cmp_nvim_lsp').default_capabilities(),
                                                require('copilot_cmp').default_capabilities())

---
-- LSP servers
---

local function on_attach(client, bufnr)
    if vim.env.NVIM_AUTOFORMAT == "1" and
        client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function() vim.lsp.buf.format() end
        })
    end
end

lspconfig.tsserver.setup({})
lspconfig.html.setup({})
lspconfig.cssls.setup({})
lspconfig.lua_ls.setup {}
lspconfig.pyright.setup {}
lspconfig.clangd.setup {on_attach = on_attach}
lspconfig.rust_analyzer.setup {on_attach = on_attach}
lspconfig.gdscript.setup {}
lspconfig.emmet_ls.setup {}
lspconfig.ruff_lsp.setup {}

local prettier = {formatCommand = 'prettier "${INPUT}"', formatStdin = true}
local eslint = {
    lintCommand = "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}",
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = {"%f(%l,%c): %tarning %m", "%f(%l,%c): %rror %m"},
    lintSource = "eslint"
}
lspconfig.efm.setup {
    on_attach = on_attach,
    init_options = {documentFormatting = true},
    settings = {
        rootMarkers = {".git/"},
        languages = {
            lua = {{formatCommand = "lua-format -i", formatStdin = true}},
            python = {{formatCommand = "black --quiet -", formatStdin = true}},
            typescript = {prettier, eslint},
            javascript = {prettier, eslint},
            typescriptreact = {prettier, eslint},
            javascriptreact = {prettier, eslint},
            yaml = {prettier},
            json = {prettier},
            html = {prettier},
            scss = {prettier},
            css = {prettier}
        }
    }
}

local ok, ltex_extra = pcall(require, "ltex_extra")
if ok then
    local ltex_allowed_filetypes = {"gitcommit", "markdown"}
    lspconfig.ltex.setup({
        on_attach = function()
            require("ltex_extra").setup {
                load_langs = {"ru-RU", "en-US"}, -- table <string> : languages for witch dictionaries will be loaded
                init_check = true, -- boolean : whether to load dictionaries on startup
                path = vim.fn.stdpath("config") .. "/spell", -- string : path to store dictionaries. Relative path uses current working directory
                log_level = "none" -- string : "none", "trace", "debug", "info", "warn", "error", "fatal"
            }
        end,
        settings = {
            ltex = {
                -- check LSP config if you add new filetypes
                filetypes = ltex_allowed_filetypes
            }
        }
    })
end

---
-- Autocomplete
---
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

require('luasnip.loaders.from_vscode').lazy_load()
require("luasnip.loaders.from_vscode").load({paths = {"./snippets"}})

local cmp = require('cmp')
local luasnip = require('luasnip')

local select_opts = {behavior = cmp.SelectBehavior.Select}

-- Helper function for copilot_cmp
local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
        return false
    end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and
               vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match(
                   "^%s*$") == nil
end

cmp.setup({
    snippet = {expand = function(args) luasnip.lsp_expand(args.body) end},
    sources = {
        -- Copilot Source
        {name = "copilot", group_index = 2}, -- Other Sources
        {name = "path", group_index = 2},
        {name = "nvim_lsp", group_index = 2, keyword_length = 1},
        {name = 'buffer', group_index = 3, keyword_length = 3},
        {name = "luasnip", group_index = 2, keyword_length = 2}
    },
    window = {documentation = cmp.config.window.bordered()},
    formatting = {
        fields = {'menu', 'abbr', 'kind'},
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = 'λ',
                luasnip = '⋗',
                buffer = 'Ω',
                path = '🖫'
            }

            item.menu = menu_icon[entry.source.name]
            return item
        end
    },
    mapping = {
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),

        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-y>'] = cmp.mapping.confirm({select = true}),
        ['<CR>'] = cmp.mapping.confirm({select = false}),

        ['<C-f>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(1) then
                luasnip.jump(1)
            else
                fallback()
            end
        end, {'i', 's'}),

        ['<C-b>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {'i', 's'}),

        ["<Tab>"] = vim.schedule_wrap(function(fallback)
            local col = vim.fn.col('.') - 1

            if cmp.visible() and has_words_before() then
                cmp.select_next_item({behavior = cmp.SelectBehavior.Select})
            elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                fallback()
            else
                cmp.complete()
            end
        end),

        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item(select_opts)
            else
                fallback()
            end
        end, {'i', 's'})
    }
})

-- -- if client.name == 'pyright' then
-- --     -- optimize imports with pyright
-- --     vim.keymap.set("n", "<leader>voi",
-- --         function()
-- --             vim.lsp.buf.execute_command({
-- --                 command = 'pyright.organizeimports',
-- --                 arguments = { vim.uri_from_bufnr(0) }
-- --             })
-- --         end, { unpack(opts), desc = 'LSP Organize Imports' })
-- -- end
--
--
--
-- -- Autoformat on save if $AUTOFORMAT is set to 1
-- if vim.env.AUTOFORMAT == "1" then
--     vim.api.nvim_create_autocmd("BufWritePre", {
--         buffer = bufnr,
--         callback = function()
--             vim.lsp.buf.format { async = false }
--         end
--     })
-- end
