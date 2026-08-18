vim.opt.colorcolumn = "80"
vim.opt.textwidth = 0
vim.opt.termguicolors = true
if require("config.platform").is_windows then
    vim.opt.guifont = "Iosevka Nerd Font:h12"
end

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.formatoptions:remove({ "t" })

vim.opt.showmode = false
vim.opt.smartindent = true

-- Wrapping
vim.opt.breakindentopt = { "shift:0" }
vim.opt.showbreak = "↳ "

vim.opt.backup = false
vim.opt.undofile = true
vim.opt.swapfile = false

-- Enable local configuration
vim.opt.exrc = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Preview substitutions live and higlight only when searching
vim.opt.inccommand = "split"
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 4
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Show return characters
vim.wo.list = true
vim.wo.listchars = "tab:>-,extends:>,precedes:<,nbsp:␣"

-- Configure how new splits should be opened
vim.opt.splitright = true

-- Custom highlighting in diff mode
vim.opt.diffopt:append({ "algorithm:histogram", "linematch:50" })

-- Open diff in vertical split
vim.opt.diffopt:append({ "vertical" })

-- Enable syntax highlight in code blocks
vim.g.markdown_fenced_languages = {
    "asm",
    "pascal",
    "perl",
    "lisp",
    "python",
    "cpp",
    "py=python",
    "javascript",
    "php",
    "java",
    "rust",
    "php",
    "sql",
    "rb=ruby",
    "ruby",
    "go",
    "lua",
    "bash=sh",
    "java",
    "javascript",
    "js=javascript",
    "json=javascript",
    "tsx=typescript",
    "ts=typescript",
    "vue",
    "gdscript",
    "typescript",
    "html",
    "css",
    "scss",
    "yaml",
    "toml",
    "tex",
    "nix",
    "nginx",
}

-- Use treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevelstart = 99
vim.cmd([[ set nofoldenable]])

-- Enable markdown folding (can be slow!)
vim.g.markdown_folding = 1

-- Set window title to the current base directory
vim.opt.title = true
vim.opt.titlestring = "%{expand('%:p:h:t')}"

-- Netrw settings
vim.g.nerw_keepdir = 0 --  avoid the move files error.
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25
if not require("config.platform").is_windows then
    vim.g.netrw_localcopydircmd = "cp -r" -- fix netrw recursive dir copy
end

-- osc52 Clipboard
vim.g.clipboard = {
  name = "osc52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function() return {} end,
    ["*"] = function() return {} end,
  },
}

-- Cursorline highlighting control
--  Only have it on in the active buffer
vim.opt.cursorline = true -- Highlight the current line
local group = vim.api.nvim_create_augroup("CursorLineControl", { clear = true })
local set_cursorline = function(event, value, pattern)
    vim.api.nvim_create_autocmd(event, {
        group = group,
        pattern = pattern,
        callback = function()
            vim.opt_local.cursorline = value
        end,
    })
end
set_cursorline("WinLeave", false)
set_cursorline("WinEnter", true)
set_cursorline("FileType", false, "TelescopePrompt")

-- Hide line numbers and signs for specific files
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = { "QuickNote.md", "keyboard_shortcut.md", "TODO.md" },
    callback = function()
        -- Hide line numbers and signs
        vim.opt.number = false
        vim.opt.relativenumber = false
        vim.opt.statuscolumn = ""
        vim.opt.wrap = false
    end,
})

-- Enable autoread and set up checking triggers
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    command = "if mode() != 'c' | checktime | endif",
    pattern = "*",
})

-- Remember cursor position
local lastplace = vim.api.nvim_create_augroup("LastPlace", {})
vim.api.nvim_clear_autocmds({ group = lastplace })
vim.api.nvim_create_autocmd("BufReadPost", {
    group = lastplace,
    pattern = { "*" },
    desc = "remember last cursor place",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- make Neovim’s jobs use a login+interactive Zsh
local zsh = vim.fn.exepath("zsh")
if zsh ~= "" and not require("config.platform").is_windows then
    vim.opt.shell = zsh
    vim.opt.shellcmdflag = "-lic"
end

-- Fix file types
vim.filetype.add({
  extension = {
    sh = "sh",
    bash = "sh",
  },
})
