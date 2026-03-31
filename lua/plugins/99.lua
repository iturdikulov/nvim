return {
    "ThePrimeagen/99",
    config = function()
        local _99 = require("99")

        -- For logging that is to a file if you wish to trace through requests
        -- for reporting bugs, i would not rely on this, but instead the provided
        -- logging mechanisms within 99.  This is for more debugging purposes
        local cwd = vim.uv.cwd()
        local basename = vim.fs.basename(cwd)
        _99.setup({
            provider = _99.Providers.CursorAgentProvider,
            model = "auto",
            logger = {
                level = _99.DEBUG,
                path = "/tmp/" .. basename .. ".99.debug",
                print_on_error = true,
            },
            -- When setting this to something that is not inside the CWD tools
            -- such as claude code or opencode will have permission issues
            -- and generation will fail refer to tool documentation to resolve
            -- https://opencode.ai/docs/permissions/#external-directories
            -- https://code.claude.com/docs/en/permissions#read-and-edit
            tmp_dir = "./tmp",
        })

        -- take extra note that i have visual selection only in v mode
        -- technically whatever your last visual selection is, will be used
        -- so i have this set to visual mode so i dont screw up and use an
        -- old visual selection
        --
        -- likely ill add a mode check and assert on required visual mode
        -- so just prepare for it now
        vim.keymap.set("v", "<leader>9v", function()
            _99.visual()
        end)

        vim.keymap.set("n", "<leader>99", function()
            _99.vibe()
        end)

        --- if you have a request you dont want to make any changes, just cancel it
        vim.keymap.set("n", "<leader>9x", function()
            _99.stop_all_requests()
        end)

        vim.keymap.set("n", "<leader>9s", function()
            _99.search()
        end)

        vim.keymap.set("n", "<leader>9o", function()
            _99.open()
        end)

        vim.keymap.set("n", "<leader>9m", function()
            require("99.extensions.telescope").select_model()
        end)

        vim.keymap.set("n", "<leader>9p", function()
            require("99.extensions.telescope").select_provider()
        end)

        --- if you have a request you dont want to make any changes, just cancel it
        vim.keymap.set("n", "<leader>9x", function()
            _99.stop_all_requests()
        end)

        vim.keymap.set("n", "<leader>9X", function()
            _99.clear_previous_requests()
        end)
    end,
}
