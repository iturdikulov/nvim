return {
    "nvim-telescope/telescope.nvim",

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    config = function()
        local is_windows = require("config.platform").is_windows
        local rg = vim.fn.exepath("rg")

        local find_command
        if rg ~= "" then
            find_command = { rg, "--files", "--color", "never" }
            if not is_windows then
                vim.list_extend(find_command, { "-L", "--sortr=modified" })
            end
        end

        require("telescope").setup({
            defaults = rg ~= "" and {
                vimgrep_arguments = {
                    rg,
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                },
            } or nil,
            pickers = {
                find_files = {
                    find_command = find_command,
                    mappings = {
                        n = {
                            ["cd"] = function(prompt_bufnr)
                                local selection = require(
                                    "telescope.actions.state"
                                ).get_selected_entry()
                                local dir =
                                    vim.fn.fnamemodify(selection.path, ":p:h")
                                require("telescope.actions").close(prompt_bufnr)
                                -- Depending on what you want put `cd`, `lcd`, `tcd`
                                vim.cmd(string.format("silent lcd %s", dir))
                            end,
                        },
                    },
                },
            },
        })

        local builtin = require("telescope.builtin")

        vim.keymap.set("n", "<M-F>", builtin.oldfiles, { desc = "Old [f]iles" })
        vim.keymap.set(
            "n",
            "<M-f>",
            builtin.find_files,
            { desc = "[F]ind [f]iles" }
        )

        vim.keymap.set("n", "<leader>ff", function()
            if vim.fn.filereadable(".git/HEAD") == 1 then
                builtin.git_files()
            else
                vim.notify("Not a git repository", "error")
            end
        end, { desc = "Git [f]iles" })

        vim.keymap.set("n", "<leader>fk", function()
            builtin.keymaps()
        end, { desc = "[F]ind [k]eymaps" })

        vim.keymap.set(
            "n",
            "<leader>fc",
            builtin.commands,
            { desc = "Find [c]ommands" }
        )
        vim.keymap.set(
            "n",
            "<leader>fC",
            builtin.command_history,
            { desc = "Find [C]ommands history" }
        )

        vim.keymap.set("n", "<leader>fws", function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)

        vim.keymap.set("n", "<leader>fWs", function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set("n", "<leader>fs", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Grep file[s]" })
        vim.keymap.set(
            "n",
            "<leader>fh",
            builtin.help_tags,
            { desc = "[H]elp tags" }
        )
        vim.keymap.set(
            "n",
            "<leader>fb",
            builtin.buffers,
            { desc = "[F]ind [b]uffers" }
        )
    end,
}
