return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VimEnter",
    config = function()
        require("todo-comments").setup({
            signs = false,
            highlight = {
                comments_only = false, -- uses treesitter to match keywords in comments only
                exclude = {}, -- list of file types to exclude highlighting
            },
            keywords = {
                NOW = { color = "warning" },
                REPEAT = { color = "test" },
                DONE = {
                    color = "hint",
                    alt = { "CLOSED", "FIXED" },
                },
                PROJECT = { color = "warning" },
            },
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
            ":TodoTelescope keywords=TODO,NOW<CR>",
            { desc = "Show todo list" }
        )

        vim.keymap.set("n", "<leader>td", function()
            -- Get the current line
            local current_line = vim.fn.getline(".")
            -- Get the current line number
            local line_number = vim.fn.line(".")
            if string.find(current_line, "TODO:") then
                local new_line = current_line:gsub("TODO:", "DONE:")
                vim.fn.setline(line_number, new_line)
            elseif string.find(current_line, "DONE:") then
                local new_line = current_line:gsub("DONE:", "TODO:")
                vim.fn.setline(line_number, new_line)
            else
                vim.fn.setline(line_number, "- TODO: " .. current_line)
            end
        end, { desc = "Toggle task done or not" })

        vim.keymap.set("n", "<leader>tD", function()
            local buf = vim.api.nvim_get_current_buf()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

            local filename = vim.api.nvim_buf_get_name(buf)
            if filename == "" then
                print("File must be saved before archiving DONE items.")
                return
            end

            local dir = vim.fn.fnamemodify(filename, ":h")
            local name = vim.fn.fnamemodify(filename, ":t:r")
            local ext = vim.fn.fnamemodify(filename, ":e")

            local archive_path =
                string.format("%s/%s_archive.%s", dir, name, ext)

            local remaining = {}
            local archived = {}

            for _, line in ipairs(lines) do
                if line:match("DONE:") then
                    table.insert(archived, line)
                else
                    table.insert(remaining, line)
                end
            end

            -- Replace buffer with remaining (non-DONE) lines
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, remaining)

            -- Append archived lines to archive file
            local f = io.open(archive_path, "a+")
            if f then
                for _, l in ipairs(archived) do
                    f:write(l .. "\n")
                end
                f:close()
                vim.notify("Archived DONE items → " .. archive_path)
            else
                vim.notify("Could not open or create archive file.")
            end
        end, { desc = "Archive DONE: items" })
    end,
}
