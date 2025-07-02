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

        map("<m-h><m-a>", function()
            harpoon:list():add()
        end, "Add File")

        map("<m-h><m-h>", function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end, "Open harpoon UI")

        -- Set <space>1..<space>5 be my shortcuts to moving to the files
        for _, idx in ipairs { 1, 2, 3, 4, 5 } do
          vim.keymap.set("n", string.format("<space>%d", idx), function()
            harpoon:list():select(idx)
          end)
        end

        -- Toggle previous & next buffers stored within Harpoon list
        map("<C-M-P>", function()
            harpoon:list():next()
        end, "Toggle Previous buffer")

        map("<C-M-N>", function()
            harpoon:list():prev()
        end, "Toggle Next buffer")
    end
}
