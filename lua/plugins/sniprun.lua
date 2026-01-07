return {
    "michaelb/sniprun",
    branch = "master",

    build = "sh install.sh",
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

    config = function()
        require("sniprun").setup({
            selected_interpreters = { "JS_TS_deno" },
            repl_enable = { "JS_TS_deno" },
        })

        vim.keymap.set(
            "v",
            "<leader>ee",
            "<Plug>SnipRun",
            { silent = true, desc = "Sniprun: run code snippet with selection" }
        )
        vim.keymap.set(
            "n",
            "<leader>ee",
            "<Plug>SnipRun",
            { silent = true, desc = "Sniprun: run code snippet under cursor" }
        )
        vim.keymap.set(
            "n",
            "<leader>eE",
            "<Plug>SnipRunOperator",
            { silent = true, desc = "Sniprun: operator mode (text-objecs)" }
        )
    end,
}
