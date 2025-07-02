return {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
    config = function ()
        local map = function(mode, lhs, rhs, desc)
            if desc then desc = "[Refactoring] " .. desc end

            vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
        end

        local refactoring = require('refactoring')
        local ref = refactoring.refactor

        -- Prompt for a refactor to apply when the remap is triggered
        map({"n", "x"}, "<leader>rr", function() refactoring.select_refactor() end,
            "Prompt for a refactor")

        -- Extract function, supports only visual mode
        map("x", "<leader>re", function() ref('Extract Function') end,
            "Extract Function")
        map("x", "<leader>rf", function() ref('Extract Function To File') end,
            "Extract Function To File")

        -- Extract variable, supports only visual mode
        map("x", "<leader>rv", function() ref('Extract Variable') end,
            "Extract Variable")

        -- Inline var, supports both normal and visual mode
        map({"n", "x"}, "<leader>ri", function() ref('Inline Variable') end,
            "Inline Variable")

        -- Extract block, supports only normal mode
        map("n", "<leader>rb", function() ref('Extract Block') end, "Extract Block")
        map("n", "<leader>rbf", function() ref('Extract Block To File') end,
            "Extract Block To File")

        ---
        -- Debug
        ---

        -- Place printf at the cursor position
        -- You can also use below = true here to to change the position of the printf
        -- statement (or set two remaps for either one). This remap must be made in normal mode.
        map("n", "<leader>rp", function() refactoring.debug.printf({below = false}) end,
            "Debug printif")

        -- Place print_var at the cursor position, supports both visual and normal mode
        map({"x", "n"}, "<leader>rv", function() refactoring.debug.print_var() end,
            "Debug print_var")

        -- Cleanup, only normal mode
        map("n", "<leader>rc", function() refactoring.debug.cleanup({}) end, "Debug cleanup")
    end
}
