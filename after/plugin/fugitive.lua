if not vim.g.loaded_fugitive then return end

-- Automatically start insert mode when opening gitcommit buffers
vim.cmd [[
    autocmd FileType gitcommit startinsert
]]

local Personal_Fugitive = vim.api.nvim_create_augroup("Personal_Fugitive", {})

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufWinEnter", {
    group = Personal_Fugitive,
    pattern = "*",
    callback = function()
        local map = function(lhs, rhs, desc)
            local bufnr = vim.api.nvim_get_current_buf()
            if desc then desc = "[Fugitive] " .. desc end

            vim.keymap.set("n", lhs, rhs,
                           {buffer = bufnr, desc = desc, remap = false})
        end

        if vim.bo.ft ~= "fugitive" then return end

        map("<leader>pp", function() vim.cmd.Git('push') end, "Git push")

        -- rebase always
        map("<leader>pP", function() vim.cmd.Git({'pull --rebase'}) end,
            "Git pull")

        -- NOTE: It allows me to easily set the branch i am pushing and any tracking
        -- needed if i did not set the branch up correctly
        map("<leader>pt", ":Git push -u origin ", "Git push origin");
        map("<leader>pT",
            ":Git push -o merge_request.create --set-upstream origin -u origin ",
            "Git push with MR");
    end
})

-- fugitive git bindings
local function showFugitiveGit()
    if vim.fn.FugitiveHead() ~= '' then
        vim.cmd [[
        :vertical Git
        setlocal nonumber
        setlocal norelativenumber
        ]]
    end
end
local function toggleFugitiveGit()
    if vim.fn.buflisted(vim.fn.bufname('fugitive:///*/.git//$')) ~= 0 then
        vim.cmd [[ execute ":bdelete" bufname('fugitive:///*/.git//$') ]]
    else
        showFugitiveGit()
    end
end

-- Main Keymaps

local map = function(lhs, rhs, desc)
    if desc then desc = "[Fugitive] " .. desc end

    vim.keymap.set("n", lhs, rhs, {silent = true, desc = desc})
end

-- Grep with quickfix list
vim.cmd[[
command! -nargs=+ Ggr execute 'Ggrep' <q-args> | cw
]]

map('<leader>gg', toggleFugitiveGit, 'toggle panel')
map("<leader>gs", vim.cmd.Git, "panel")

map("<leader>gl", ":Gclog<CR>", "log")
map("<leader>gL", ":G log -p -S<Space>", "Git History for Code")

map("<leader>gb", ":Git branch<Space>", "branch")

map("<leader>gd", ":Gdiffsplit<CR>", "diff split")
map("<leader>gD", ":Git diff<CR>", "diff")
map("<leader>ge", ":Gedit<CR>", "edit")

-- capitalize W/R to reduce unwanted changes
map("<leader>gW", ":Gwrite<CR>", "write")
map("<leader>gR", ":Gread<CR>", "read")

map("<leader>ga", ":Git commit -v -q --amend<CR>", "ammend")
map("<leader>gA", ":Git add -p<CR>", "add with patch")

map("<leader>gp", ":Ggrep<Space>", "grep")
map("<leader>gP", ":Ggr<Space>", "grep with quickfix-list")

map("<leader>gm", ":GMove<Space>", "move")
map("<leader>go", ":Git checkout<Space>", "checkout")

-- LLM: commit message
vim.keymap.set('n', '<leader>gc', function()
  local prompt = [[Given a git diff output, generate a concise commit message following these specifications:
- NEVER use code blocks in your output and wrapping output in code block
- Each line should be ≤ 80 characters wide
- Break longer lines with proper line wrapping
- Use present tense and imperative mood
- Focus on the "what" and "why" of the changes, use Add, Fix, Refactor, Update, Bump keywords
- Exclude any metadata, comments, or explanations
- Maximum length: 256 words
- Be specific but concise
- Return only the commit message text
]]
  local command = "git diff --cached | llm " .. vim.fn.shellescape(prompt)
  local output = vim.fn.systemlist(command)
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  for _, line in ipairs(output) do
    vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1] - 1, false, { line })
    cursor[1] = cursor[1] + 1
  end
end, { desc = "[llm] commit message" })
