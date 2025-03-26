local ok, _ = pcall(require, "mini.ai")
if not ok then return end

-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]parenthen
--  - yinq - [Y]ank [I]nside [N]ext [']quote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup { n_lines = 500 }

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup({
    -- Make `=` insert parts with spaces. `input` pattern stays the same.
    custom_surroundings = {
        ['='] = { output = { left = '==', right = '==' } },
    }
})

-- Use `ss` to subtititute single char
vim.keymap.set("n", "ss", "s")

-- Align text interactively
-- main option modifiers: [s]plit, [j]ustify side, [m] enter merge delimeter
--
-- - ga - start
-- - gA - start with preview
-- - gas-   - [S]plit by `-`
-- - gaipjc - [J]ustify [I]nner [P]aragraph [C]enter
-- - Vipgajr - [V]isual select [I]nner [P]aragraph [J]ustify [R]ight
require('mini.align').setup()

-- -- Track files visits and provide ui to select them
-- -- plus some additional features (not using them)
-- require('mini.visits').setup()
-- local make_select_path = function(select_global, recency_weight)
--     local visits = require('mini.visits')
--     local sort = visits.gen_sort.default({ recency_weight = recency_weight })
--     local select_opts = { sort = sort }
--     return function()
--         local cwd = select_global and '' or vim.fn.getcwd()
--         visits.select_path(cwd, select_opts)
--     end
-- end
-- local visitsMap = function(lhs, desc, ...)
--     vim.keymap.set('n', lhs, make_select_path(...), { desc = desc })
-- end
-- visitsMap('<Leader>o', 'Select recent (all)', true, 1)
-- visitsMap('<Leader>O', "Select recent (cwd)", false, 1)

-- Text edit operators
-- (1 + 1) - g=i), to evaluate, g= also supporting visual selection
-- T*his is example - gx[iw] w., swap This and is, use gxx with j./k. motions to swap lines
-- T*his is example - gmiw, duplicate This word, use 2gmm to duplicate next 2 lines
-- T*his is example - griw, replace This word with yank buffer, use grr to replace line
-- b, c, a          - gss, sort into a, b, c, use gsip to sort innner paragrap
require('mini.operators').setup(
    { -- Exchange text regions
        exchange = {
            prefix = 'gX',
        },
    }
)

-- Files
--
require('mini.files').setup {
    options = {
        use_as_default_explorer = false,
    },
}
vim.keymap.set("n", "<leader>pV", MiniFiles.open)

-- ... and there is more!
--  Check out: https://github.com/echasnovski/mini.nvim
