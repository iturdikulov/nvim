return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require('todo-comments').setup {
            signs = false
        }

        vim.keymap.set("n", "]t", function()
            require("todo-comments").jump_next({
                keywords = { "ERROR", "WARNING", "WARN" },
            })
        end, { desc = "Next error/warning todo comment" })

        vim.keymap.set("n", "]T", function()
            require("todo-comments").jump_next()
        end, { desc = "Next todo comment" })

        vim.keymap.set("n", "[t", function()
            require("todo-comments").jump_prev()
        end, { desc = "Previous todo comment" })

        vim.keymap.set('n', '<leader>ft', ":TodoTelescope keywords=TODO,NEXT,WARN<CR>", { desc = "Show todo list" })
    end,
}
