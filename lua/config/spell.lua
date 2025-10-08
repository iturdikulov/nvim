-- File types to enable spellcheck
local spell_types = { "text", "plaintex", "typst", "gitcommit", "markdown",
"html", "python", "javascript", "javascriptreact", "c", "cpp", "rust" }

-- Set global spell option to false initially to disable it for all file types
vim.opt.spell = false

-- Create an augroup for spellcheck to group related autocommands
vim.api.nvim_create_augroup("Spellcheck", { clear = true })

-- Create an autocommand to enable spellcheck for specified file types
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = "Spellcheck", -- Grouping the command for easier management
  pattern = spell_types, -- Only apply to these file types
  callback = function()
    vim.opt_local.spell = true -- Enable spellcheck for these file types
    vim.opt.spelllang = { "en", "cjk" }
    vim.opt.spelloptions = "camel"
    vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add" ..
                 ',' .. vim.fn.stdpath("config") .. "/spell/ru.utf-8.add"
    if vim.fn.expand('%:t'):match(".ru.") then
        vim.opt_local.spelllang = { "ru", "en", "cjk" }
    end
  end,
  desc = "Enable spellcheck for defined file-types", -- Description for clarity
})
