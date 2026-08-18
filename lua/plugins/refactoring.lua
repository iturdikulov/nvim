return {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
        "lewis6991/async.nvim",
    },
    lazy = false,
    config = function()
        local map = function(mode, lhs, rhs, desc, expr)
            if desc then desc = "[Refactoring] " .. desc end

            vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, expr = expr })
        end

        local refactoring = require("refactoring")
        local debug = require("refactoring.debug")

        map({ "n", "x" }, "<leader>rr", function()
            refactoring.select_refactor()
        end, "Prompt for a refactor")

        map("x", "<leader>re", function()
            return refactoring.extract_func()
        end, "Extract Function", true)
        map("x", "<leader>rf", function()
            return refactoring.extract_func_to_file()
        end, "Extract Function To File", true)

        map("x", "<leader>rv", function()
            return refactoring.extract_var()
        end, "Extract Variable", true)

        map({ "n", "x" }, "<leader>ri", function()
            return refactoring.inline_var()
        end, "Inline Variable", true)

        map("n", "<leader>rp", function()
            return debug.print_loc({ output_location = "above" })
        end, "Debug print location", true)
        map("n", "<leader>rV", function()
            return debug.print_var({ output_location = "below" }) .. "iw"
        end, "Debug print variable", true)
        map("x", "<leader>rV", function()
            return debug.print_var({ output_location = "below" })
        end, "Debug print variable", true)
        map({ "n", "x" }, "<leader>rc", function()
            return debug.cleanup({ restore_view = true })
        end, "Debug cleanup", true)
    end
}
