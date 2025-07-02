return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VimEnter",
    config = function()
        require("todo-comments").setup({
            signs = false,
            keywords = {
                NOW = { icon = "⏲ ", color = "warning" },
            }
        })

        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Enable todo-comments for text",
            group = vim.api.nvim_create_augroup(
                "user.todo.text",
                { clear = true }
            ),
            callback = function(ev)
                local config = require("todo-comments.config")
                local comments_only = string.match(ev.file, "%.md$") == nil
                    and string.match(ev.file, "%.txt$") == nil
                    and string.match(ev.file, "%.adoc$") == nil
                    and string.match(ev.file, "%.asciidoc$") == nil
                config.options.highlight.comments_only = comments_only
            end,
        })

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

        vim.keymap.set(
            "n",
            "<leader>ft",
            "TodoTelescope<CR>",
            { desc = "Show todo list" }
        )
    end,
}
