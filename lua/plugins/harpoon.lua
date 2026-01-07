return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require('harpoon')
        harpoon:setup({
          settings = {
            save_on_toggle = true,
          },
        })

        local map = function(lhs, rhs, desc)
            if desc then
                desc = "[Harpoon] " .. desc
            end

            vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
        end

        map("<C-M-l>", function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end, "Open harpoon UI")

        map("<C-M-h>", function()
            harpoon:list():add()
            local file = vim.fn.expand("%:t")
            vim.notify("Added " .. file .. " to harpoon")
        end, "Add File")

        -- vim.keymap.set("n", "<C-l>", function() harpoon:list():select(1) end)
        -- vim.keymap.set("n", "<C-h>", function() harpoon:list():select(2) end)
        -- vim.keymap.set("n", "<C-j>", function() harpoon:list():select(3) end)
        -- vim.keymap.set("n", "<C-k>", function() harpoon:list():select(4) end)

        -- Toggle previous & next buffers stored within Harpoon list
        map("<C-M-P>", function()
            harpoon:list():next()
        end, "Toggle Previous buffer")

        map("<C-M-N>", function()
            harpoon:list():prev()
        end, "Toggle Next buffer")
    end
}
