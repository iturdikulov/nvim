require("Personal.set")
require("Personal.remap")
require("Personal.langmap")
require("Personal.lazy")
require("Personal.checkbox")
require("Personal.mpv")
vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/Personal/xxd.vimrc")

local augroup = vim.api.nvim_create_augroup
local PersonalGroup = augroup('Personal', {})
local PersonalViewGroup = augroup('PersonalView', {})

local autocmd = vim.api.nvim_create_autocmd

function R(name) require("plenary.reload").reload_module(name) end

-- reload nvim config
function _G.ReloadConfig()
    local files_reloaded = 0
    for name, _ in pairs(package.loaded) do
        if name:match('^Personal') then
            package.loaded[name] = nil
            files_reloaded = files_reloaded + 1
        end
    end

    -- reload all from ~/.config/nvim/after/plugin/*.lua
    for _, file in pairs(vim.fn.globpath(
        vim.fn.stdpath("config") .. "/after/plugin",
        "*.lua", false, true)) do
        dofile(file)
        files_reloaded = files_reloaded + 1
    end

    dofile(vim.fn.stdpath("config") .. "/init.lua")
    vim.notify("Reloaded " .. files_reloaded .. " files")
end

local yank_group = augroup('HighlightYank', {})
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 40 })
    end
})

-- Remove trailing whitespace on save
autocmd({ "BufWritePre" },
    { group = PersonalGroup, pattern = "*", command = [[%s/\s\+$//e]] })

-- Set listchars for specific filetypes
autocmd({ "BufRead" }, {
    group = PersonalViewGroup,
    pattern = "*",
    callback = function() vim.wo.listchars = GLOBAL_LISTCHARS end
})

-- Set *.asc files to markdown filetype
autocmd({ 'BufWinEnter' }, {
    desc = 'ASC files syntax to markdown',
    pattern = { '*.asc' },
    callback = function() vim.opt_local.filetype = 'markdown' end
})

vim.api.nvim_create_user_command("CopySearch", function(args)
    vim.fn.setreg(args.reg, "")
    vim.api.nvim_cmd({
        cmd = "substitute",
        args = {
            string.format([[//\=setreg('%s', submatch(0), 'al')/n]], args.reg)
        },
        range = { args.line1, args.line2 }
    }, {})
end, { range = true, register = true })
