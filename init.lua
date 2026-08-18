require("config.lazy")
require("config.set")
require("config.remap")
require("config.spell")
require("config.checkbox")
local platform = require("config.platform")
if not platform.is_windows then
    require("config.gnupg")
else
    vim.schedule(function()
        vim.notify(
            "Windows compatibility mode: skipped config.gnupg, plugins: devcontainers.nvim, nvim-dap, nvim-dap-view, nvim-lint, sniprun, asm_lsp",
            vim.log.levels.INFO
        )
    end)
end
require("config.utils")
vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/config/xxd.vimrc")
