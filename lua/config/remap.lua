-- extrueit terminal mode in the builtin terminal with a shortcut that is a bit
-- easier for people to discover. Otherwise, you normally need to press
-- <c-\><c-n>, which is not what someone will guess without a bit more
-- experience.
vim.keymap.set("t", "<c-n><c-n>", "<c-\\><c-n>", { desc = "Escape Escape exits terminal mode" })

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- NOTE: this keymap for term, in our case Ctrl-Backspace
vim.keymap.set("i", "<C-H>", "<C-W>", { noremap = true })

-- Save on :W, quit on :Q, this is workarounds for this cases, sometimes I type
-- :W instead :w...
vim.api.nvim_create_user_command('W', function() vim.cmd('w') end, {})
vim.api.nvim_create_user_command('Q', function() vim.cmd('q') end, {})

-- Use Meta-S for saving, also save in Insert mode
vim.keymap.set("n", "<M-w>", ":update<CR>")
vim.keymap.set("v", "<M-w>", "<C-c>:update<CR>")
vim.keymap.set("i", "<M-w>", "<C-o>:update<CR>")

-- Use different keys to increment number
--- C-a I using for tmux prefix
vim.keymap.set({"n", "x"}, "<A-a>", "<C-a>")

-- Support gf for files with spaces
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

-- move lines with C-K and C-J
vim.keymap.set("v", "<C-K>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "<C-J>", ":m '>+1<CR>gv=gv")

-- save cursor on center on next/previous search and join lines
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "J", "mzJ`z")

-- greatest remap ever, to replace selection with default register (yanked text)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
-- integrate system clipboard with <leader>y
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- special paste, which ignore delete and cut commands
vim.keymap.set({ "n", "v"}, ",p", "0p")
vim.keymap.set({ "n", "v"}, ",P", "0P")

-- delete to void register (without copy to clipboard)
vim.keymap.set({ "n", "v" }, "<leader>D", [["_d]])

-- Quickfix list navigation
vim.keymap.set("n", "<leader>j", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>K", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>J", "<cmd>lprev<CR>zz")

-- Replace word under cursor -> send to command mode
vim.keymap.set("n", "<leader>/", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

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
    vim.fn.jobstart({ 'obsidian', obsidian_url })
end, { desc = "open in obsidian" })

-- Quickly Destsroy current buffer
vim.keymap.set("n", "<M-x>", "<cmd>bd<CR>")

-- Delete current file
-- TODO: need to add confirmation
vim.keymap.set("n", "<leader><Del>", "<cmd>call delete(expand('%:p')) | bdelete! %<CR>")

-- Insert new line below/upper current line
vim.keymap.set("n", "]<space>", "moo<Esc>`o")
vim.keymap.set("n", "[<space>", "moO<Esc>`o")

-- close all buffers except current one
vim.keymap.set("n", "<Leader>bd", ":%bd|e#<cr>", { desc = "Close all buffers except current" })

-- Reload Config
function _G.ReloadConfig()
	for name, _ in pairs(package.loaded) do
		if name:match("^user") and not name:match("nvim-tree") then
			package.loaded[name] = nil
		end
	end

	dofile(vim.env.MYVIMRC)
	vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
end
vim.keymap.set("n", "<leader>R", "<cmd>lua ReloadConfig()<CR>", { desc = "Reload nvim config" })

-- requires some external tools

-- cd into current file path
vim.keymap.set("n", "<Leader>%", function()
    vim.cmd("!cd %:p:h")
end, { desc = "cd into current file path" })

-- Disable internal PageUp/PageDown, to use it in telescope/other places
vim.keymap.set("n", "<PageUp>", "<NOP>")
vim.keymap.set("n", "<PageDown>", "<NOP>")

-- gX: Web search
vim.keymap.set('n', '<leader>gs', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.fn.expand('<cword>')))
end)
vim.keymap.set('x', '<leader>gs', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.trim(table.concat(
    vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type=vim.fn.mode() }), ' '))))
  vim.api.nvim_input('<esc>')
end)

-- Rename linked file
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
