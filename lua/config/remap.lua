-- NEXT: need refactor this file


-- NOTE: set this before loading package manager
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- extrueit terminal mode in the builtin terminal with a shortcut that is a bit
-- easier for people to discover. Otherwise, you normally need to press
-- <c-\><c-n>, which is not what someone will guess without a bit more
-- experience.
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Escape Escape exits terminal mode" })

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- NOTE: this keymap for xst/st term, in our case Ctrl-Backspace
vim.keymap.set("i", "<C-H>", "<C-W>", { noremap = true })

-- Save on :W, this is workaround, sometimes I type :W instead :w...
vim.api.nvim_create_user_command('W', function() vim.cmd('w') end, {})

-- Use Meta-S for saving, also in Insert mode
vim.keymap.set("n", "<M-s>", ":update<CR>")
vim.keymap.set("v", "<M-s>", "<C-c>:update<CR>")
vim.keymap.set("i", "<M-s>", "<C-o>:update<CR>")

-- Use different keys to increment number
--- C-a I using for different things
vim.keymap.set({"n", "x"}, "<A-a>", "<C-a>")

-- gf files with spaces
vim.keymap.set("n", "gF", function()
    local line = vim.fn.getline(".")
    -- Remove 'directory:' from line
    local path = line:gsub("directory:", "")

    -- Remove leading spaces from path
    path = path:gsub("^%s+", "")

    -- Remove leading - from path
    path = path:gsub("^-", "")

    -- Remove quotes from path
    path = path:gsub('"', "")

    -- Go to path, using gf
    vim.cmd("e " .. path)
end, { desc = "gf files with spaces" })

-- move lines
vim.keymap.set("v", "<C-J>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<C-K>", ":m '<-2<CR>gv=gv")

-- save cursor on center
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever, to replace selection with default register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
-- integrate system clipboard with <leader>y
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
-- delete to void register
vim.keymap.set({ "n", "v" }, "<leader>D", [["_d]])

-- Quickfix list navigation
-- TODO: need check and fix
vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Replace word under cursor -> send to command mode
vim.keymap.set("n", "<leader>S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Open netrw in current directory
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Make current file executable
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true })

-- Launch script using $TERMINAL
vim.keymap.set("n", "<leader>o", "<cmd>!$TERMINAL %<CR>", { silent = true })

-- Open file in external program (xdg-open)
vim.keymap.set("n", "<leader>O", "<cmd>!xdg-open %<CR>", { silent = true, desc = "Open current file with xdg-open" })

--- Open file in obsidian, file is current buffer name without .md extension
vim.keymap.set("n", "<leader>to", function()
    local bufname = vim.fn.expand("%:t:r")
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local obsidian_url = "obsidian://adv-uri?vault=Wiki&filepath=" .. bufname .. "&line=" .. line .. "&column=" .. col
    vim.fn.jobstart({ 'obsidian_open', obsidian_url })
end, { desc = "open in obsidian" })

-- Quickly Destsroy current buffer
vim.keymap.set("n", "<M-x>", "<cmd>bd<CR>")

-- Delete current file
-- TODO: need add confirmation
vim.keymap.set("n", "<S-M-Del>", "<cmd>call delete(expand('%:p')) | bdelete! %<CR>")

-- Toggle signcolumn and line numbers
vim.keymap.set("n", "<leader>zz", function()
    vim.o.signcolumn = vim.o.signcolumn == "yes" and "no" or "yes"
    vim.o.relativenumber = not vim.o.relativenumber
    vim.o.number = not vim.o.number
end)

-- Insert new line below/upper current line
vim.keymap.set("n", "]<space>", "moo<Esc>`o")
vim.keymap.set("n", "[<space>", "moO<Esc>`o")

-- resize windows more quickly
vim.keymap.set("n", "<Leader>=", function()
    vim.cmd('exe "resize " . (winheight(0) * 3/2)')
end, { desc = "Resize window to 3/2" })

vim.keymap.set("n", "<Leader>-", function()
    vim.cmd('exe "resize " . (winheight(0) * 2/3)')
end, { desc = "Resize window to 2/3" })

-- close current buffer
vim.keymap.set("n", "<Leader>bd", ":bd<cr>", { desc = "Delete current buffer" })

-- close all buffers except current one
vim.keymap.set("n", "<Leader>bD", ":%bd|e#<cr>", { desc = "Close all buffers except current" })

-- Reload Config
vim.keymap.set("n", "<leader>vpr", "<cmd>lua ReloadConfig()<CR>", { desc = "Reload nvim config" })

-- requires some external tools

-- cd into current file path
vim.keymap.set("n", "<Leader>z%", function()
    vim.cmd("!cd %:p:h")
end, { desc = "cd into current file path" })


-- Disable internal PageUp/PageDown, to use it in telescope/other places
vim.keymap.set("n", "<PageUp>", "<NOP>")
vim.keymap.set("n", "<PageDown>", "<NOP>")

-- Google search
--  Credit: June Gunn <Leader>?/! | Google it / Feeling lucky
---@param pat string
local function google(pat)
  local query = '"' .. vim.fn.substitute(pat, '["\n]', " ", "g") .. '"'
  query = vim.fn.substitute(query, "[[:punct:] ]", [[\=printf("%%%02X", char2nr(submatch(0)))]], "g")
  do_open("https://www.google.com/search?" .. "q=" .. query)
end

-- gX: Web search
vim.keymap.set('n', '<leader>tg', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.fn.expand('<cword>')))
end)
vim.keymap.set('x', '<leader>tg', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.trim(table.concat(
    vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type=vim.fn.mode() }), ' '))))
  vim.api.nvim_input('<esc>')
end)

-- -- External commands
-- vim.keymap.set("n", "<Leader>oc",
-- ': silent !LDLIBS="-lcrypt -lcs50 -lm" clang "%" -o /tmp/a.out -lcs50 && kitty --hold -e /tmp/a.out<CR>')

--
--
-- -- search build.sh file in current directory and parent directories
-- local function search_build_sh_recursively(path)
--     local build_sh = path .. "/build.sh"
--     local build_bat = path .. "/build.bat"
--
--     if vim.fn.filereadable(build_sh) == 1 then
--         return build_sh
--     elseif vim.fn.filereadable(build_bat) == 1 then
--         return build_bat
--     end
--
--     -- if path included "Projects" then stop searching
--     local projects = vim.fn.expand("~/Projects")
--
--     -- if windows platform use different path
--     if vim.fn.has("win32") == 1 then
--         projects = vim.fn.expand("/w")
--     end
--
--     if vim.fn.fnamemodify(path, ":h") == projects then
--         return nil
--     end
--     -- if path is root then stop searching
--     if path == "/" then
--         return nil
--     end
--
--     return search_build_sh_recursively(vim.fn.fnamemodify(path, ":h"))
-- end
--
-- -- search build.sh file and run it, also run nvim-dap debugger
-- vim.keymap.set("n", "<Leader>bh", function()
--     local build_sh = search_build_sh_recursively(vim.fn.getcwd())
--     if build_sh then
--         -- save current file if it is modified
--         if vim.bo.modified then
--             vim.cmd("w")
--         end
--
--         -- run build.sh and if it exits with code 0 then run nvim-dap debugger
--         vim.cmd("silent !" .. build_sh)
--         -- if vim.v.shell_error == 0 then
--         --     vim.cmd("lua require('dap').continue()")
--         -- end
--     else
--         print("builder not found")
--     end
-- end)
--
--
-- -- run url_to_markdown_link.sh and then paste clipboard content
-- vim.keymap.set("n", "<Leader>pl", function()
--     vim.cmd("silent !url_to_markdown_link.sh")
--     local status = vim.v.shell_error
--     if status == 0 then
--         -- paste clipboard content
--         vim.cmd("normal! \"+p")
--     else
--         print("url_to_markdown_link.sh failed")
--     end
-- end, { desc = "Paste url as markdown link" })
--
-- -- run html2markdown.sh and then paste clipboard content
-- vim.keymap.set("n", "<Leader>ph", function()
--     vim.cmd("silent !html2markdown.sh")
--     local status = vim.v.shell_error
--     if status == 0 then
--         -- paste clipboard content
--         vim.cmd("normal! \"+p")
--     else
--         print("html2markdown.sh failed")
--     end
-- end, { desc = "Paste html as markdown" })

local function renameLinkedFile()
    local linkText = vim.fn.expand("<cWORD>")
    local linkedFileName = linkText:match("%((.-)%)")

    if linkedFileName then
        local newPath = vim.fn.input("New filename: ", linkedFileName)

        if newPath == "" then
            vim.notify("Empty filename", vim.log.levels.ERROR)
            return
        end

        vim.fn.rename(linkedFileName, newPath)

        -- Replace linkedFileName in curret line with newPath, escape / slaches
        vim.cmd("s/" .. vim.fn.escape(linkedFileName, "/") .. "/" .. vim.fn.escape(newPath, "/") .. "/")
    else
        print("No linked file detected.")
    end
end

vim.keymap.set("n", "<leader>rR", renameLinkedFile)
