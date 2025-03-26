local ok, conform = pcall(require, "conform")
if not ok then
    return
end

conform.setup({
    formatters_by_ft = {
        nix             = { "nixpkgs_fmt" },
        python          = { "ruff_fix", "ruff_format" },
        go              = { "goimports", "gofmt" },
        markdown        = { "deno_fmt" },
        javascript      = { "biome" },
        typescript      = { "biome" },
        typescriptreact = { "biome" },
        json            = { "biome" },
        jsonc           = { "biome" },
        yaml            = { "prettierd" },
        html            = { "prettierd" },
        scss            = { "prettierd" },
        css             = { "prettierd" },
        gdscript        = { "gdformat" },
        jinja           = { "djlint" },
        sql             = { "sqlfluff" },
        bash            = { "shfmt" },
    }
})

local function conform_format()
    conform.format({
        async = true,
        lsp_fallback = true
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
