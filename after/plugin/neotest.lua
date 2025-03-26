local ok_neotest, neotest = pcall(require, "neotest")
if not ok_neotest then
    return
end

local ok_neotest_python, neotest_python = pcall(require, "neotest-python")
if not ok_neotest_python then
    return
end

neotest.setup({
    floating = {
      border = "solid",
      max_height = 0.5,
      max_width = 0.8,
      options = {}
    },
    output = {
      enabled = true,
      open_on_run = "short"
    },
    output_panel = {
      enabled = true,
      open = "botright split | resize 15"
    },
    adapters = {
        neotest_python({}),
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
end, "neotest run the nearest test")

map("<leader>dnr",
    neotest.run.run_last,
    "neotest run the last test")

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

map("<leader>dno", function ()
    neotest.output_panel.toggle( { enter = true } )
end, "toggle the output panel")

map("]n", neotest.jump.next, "Neotest jump to the next test")
map("[n", neotest.jump.prev, "Neotest jump to the previous test")
