return {
    "nvim-neotest/neotest",
    config = function()
        local neotest = require("neotest")

        neotest.setup({
            adapters = {
                require("neotest-python"),
            },
        })

        local map = function(lhs, rhs, desc)
            if desc then
                desc = "[Neotest] " .. desc
            end

            vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
        end

        map("<leader>dnn", function()
            neotest.run.run()
        end, "run the nearest test")

        map("<leader>dnr", neotest.run.run_last, "run the last test")

        map("<leader>dnc", function()
            neotest.run.run({ strategy = "dap" })
            -- you can add here additional commands, like neotest.summary.open()
        end, "debug the nearest test")

        map("<leader>dnS", function()
            neotest.summary.open()
        end, "open the summary window")

        map("<leader>dnf", function()
            neotest.run.run(vim.fn.expand("%"))
        end, "run the current file")

        map("<leader>dna", neotest.run.attach, "attach to the nearest test")
        map("<leader>dnx", neotest.run.stop, "stop the nearest test")

        map("<leader>dnt", function()
            neotest.output.open({ enter = true })
        end, "open the output of a test result")

        map("<leader>dno", function()
            neotest.output_panel.toggle({ enter = true })
        end, "toggle the output panel")

        map("]n", neotest.jump.next, "jump to the next test")
        map("[n", neotest.jump.prev, "jump to the previous test")
    end,
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-neotest/neotest-python",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
}
