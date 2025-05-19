return {
    "stevearc/conform.nvim",
    opts = {},
    config = function()
        local conform = require("conform")

        conform.setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_fix" }, -- ruff
                go = { "goimports", "gofmt" },
                javascript = { "biome-check" },
                typescript = { "biome-check" },
                typescriptreact = { "biome-check" },
                jsx = { "biome-check" },
                json = { "biome-check" },
                jsonc = { "biome-check" },
                markdown = { "injected" },
                scss = { "biome-check" },
                css = { "biome-check" },
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

        vim.keymap.set({ "x" }, "<leader>=", function()
            conform_format()
        end, { silent = true, desc = "[Conform] format" })

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
