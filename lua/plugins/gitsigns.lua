return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                current_line_blame_opts = {
                    delay = 2000,
                    virt_text_pos = "eol",
                },
                on_attach = function(bufnr)
                    local gitsigns = require("gitsigns")

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    map("n", "]c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "]c", bang = true })
                        else
                            gitsigns.nav_hunk("next")
                        end
                    end, { desc = "Next hunk" })

                    map("n", "[c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "[c", bang = true })
                        else
                            gitsigns.nav_hunk("prev")
                        end
                    end, { desc = "Previous hunk" })

                    map(
                        "n",
                        "<leader>hp",
                        gitsigns.preview_hunk,
                        { desc = "Preview hunk" }
                    )
                    map(
                        "n",
                        "<leader>hi",
                        gitsigns.preview_hunk_inline,
                        { desc = "Preview hunk inline" }
                    )

                    map("n", "<leader>hb", function()
                        gitsigns.blame_line({ full = true })
                    end, { desc = "Blame line" })

                    map("n", "<leader>hd", gitsigns.diffthis)

                    map("n", "<leader>hD", function()
                        gitsigns.diffthis("~")
                    end, { desc = "Diff this ~" })

                    map("n", "<leader>hQ", function()
                        gitsigns.setqflist("all")
                    end)
                    map(
                        "n",
                        "<leader>hq",
                        gitsigns.setqflist,
                        { desc = "Set quickfix list" }
                    )

                    -- Stage/reset
                    map({"n", "v"},
                        "<leader>hh",
                        gitsigns.stage_hunk,
                        { desc = "Stage hunk" }
                    )
                    map(
                        "n",
                        "<leader>hr",
                        gitsigns.reset_hunk,
                        { desc = "Reset hunk" }
                    )

                    -- Toggles
                    map(
                        "n",
                        "<leader>hs",
                        gitsigns.toggle_signs,
                        { desc = "Toggle signs" }
                    )
                    map(
                        "n",
                        "<leader>tb",
                        gitsigns.toggle_current_line_blame,
                        { desc = "Toggle blame" }
                    )
                    map(
                        "n",
                        "<leader>tw",
                        gitsigns.toggle_word_diff,
                        { desc = "Toggle word diff" }
                    )

                    -- Text object
                    map(
                        { "o", "x" },
                        "ih",
                        gitsigns.select_hunk,
                        { desc = "Select hunk" }
                    )
                end,
            })
        end,
    },
}
