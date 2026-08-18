return {
    "stevearc/conform.nvim",
    init = function()
        vim.o.formatexpr = [[v:lua.require("conform").formatexpr()]]
    end,
    opts = {},
    config = function()
        local conform = require("conform")
        conform.setup({
            formatters = {
                deno_fmt = {
                    append_args = {
                        "--indent-width",
                        "4",
                        "--prose-wrap",
                        "never",
                    },
                },
                sqlfluff = {
                    args = { "format", "--dialect=postgres", "-" },
                },
            },
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_fix", "ruff_format" }, -- ruff
                go = { "goimports", "gofmt" },
                tex = { "tex-fmt" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                php = { "mago_format" },
                html = { "djlint" },
                smarty = { "djlint" },
                jsx = { "prettier" },
                vue = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
                markdown = { "injected", "deno_fmt" },
                scss = { "prettier" },
                css = { "prettier" },
                gdscript = { "gdformat" },
                sql = { "sqlfluff" },
                sh = { "shfmt" },
            },
        })

        local function conform_format()
            conform.format({
                async = true,
                lsp_fallback = true,
            })
        end

        vim.keymap.set({ "n" }, "<leader>=", function()
            vim.ui.input({
                prompt = "Do you want to format the file? [y/n]\n",
            }, function(input)
                if input == "y" then
                    conform_format()
                end
            end)
        end)
    end,
}
