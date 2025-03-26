local has_dap, dap = pcall(require, "dap")
if not has_dap then return end

local map = function(lhs, rhs, desc)
    if desc then desc = "[DAP] " .. desc end

    vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<F1>", dap.step_back, "step_back")
map("<F2>", dap.step_into, "step_into")
map("<F3>", dap.step_over, "step_over")
map("<F4>", dap.step_out, "step_out")
map("<F5>", dap.continue, "continue")
map("<F6>", function() dap.pause.toggle() end, 'Debug pause toggle')
map("<F7>", dap.goto_, "goto_")
map("<C-F9>", function()
    dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
end, 'set log point')
map("<Leader>dx", dap.close, 'close')
map("<leader>dX", dap.terminate, 'terminate')
map("<leader>dD", dap.disconnect, 'disconnect')

-- TODO:
-- disconnect vs. terminate

map("<leader>dr", dap.repl.open, "repl.open")

map("<leader>db", dap.toggle_breakpoint, "toggle_breakpoint")
map("<leader>dB",
    function() dap.set_breakpoint(vim.fn.input "[DAP] Condition > ") end,
    "set beakpoint with condition")

map("<leader>de", require("dapui").eval)
map("<leader>dE",
    function() require("dapui").eval(vim.fn.input "[DAP] Expression > ") end)

map("<Leader>dC", dap.run_to_cursor, 'run to cursor')
map("<Leader>dL", dap.repl.toggle, 'repl toggle')
map("<Leader>dr", dap.run_last, 'run last')
map("<Leader>dE",
    function() vim.cmd(":edit " .. vim.fn.stdpath('cache') .. "/dap.log") end,
    'open dap log')

-- Telescope DAP
if pcall(require, "telescope._extensions.dap") then
    local telescope = require("telescope")
    telescope.load_extension("dap")

    -- telescope-dap
    map("<leader>dlk", telescope.extensions.dap.commands,
        'Telescope DAP Commands')

    map("<leader>dlb", telescope.extensions.dap.list_breakpoints,
        'Telescope DAP List Breakpoints')

    map("<leader>dlc", telescope.extensions.dap.configurations,
        'Telescope DAP Configurations')

    map("<leader>dlv", telescope.extensions.dap.variables,
        'Telescope DAP Variables')

    map("<leader>dlf", telescope.extensions.dap.frames, 'Telescope DAP Frames')
end

-- Configure custom signs
vim.fn.sign_define("DapBreakpoint",
    { text = "ß", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition",
    { text = "ü", texthl = "", linehl = "", numhl = "" })

-- Setup cool Among Us as avatar
vim.fn.sign_define("DapStopped", { text = "ඞ", texthl = "Error" })

-- Configure repl
-- You can set trigger characters OR it will default to '.'
-- You can also trigger with the omnifunc, <c-x><c-o>
vim.cmd [[
augroup DapRepl
  au!
  au FileType dap-repl lua require('dap.ext.autocompl').attach()
augroup END
]]

-- TODO: How does terminal work?
local terminal = vim.env.TERMINAL
if terminal then
    local terminal_path = vim.fn.trim(vim.fn.system("which " .. terminal))
    dap.defaults.fallback.external_terminal = {
        command = terminal_path,
        args = { "-e" }
    }
end

-- Virtual text
local has_dap_virtual_text, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
if has_dap_virtual_text then
    dap_virtual_text.setup {
        enabled = true,

        -- DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, DapVirtualTextForceRefresh
        enabled_commands = false,

        -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_changed_variables = true,
        highlight_new_as_changed = true,

        -- prefix virtual text with comment string
        commented = false,

        show_stop_reason = true,

        -- experimental features:
        virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
        all_frames = false     -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
    }
end

-- DAP UI
local has_dap_ui, dap_ui = pcall(require, "dapui")
if has_dap_ui then
    local _ = dap_ui.setup {
        layouts = {
            {
                elements = {
                    "scopes", "breakpoints", "stacks", "watches", "repl"
                },
                size = 40,
                position = "right"
            },
            {
                elements = { { id = "console", size = 1 } },
                size = 10,
                position = "bottom"
            }
        }
    }

    -- DapUI keybindings
    map("<Leader>dut", dap_ui.toggle, 'Debug ui toggle')
    map("<Leader>duc", function() dap_ui.close({ reset = true }) end,
        'Debug ui close')
    map("<Leader>duo", function() dap_ui.open({ reset = true }) end,
        'Debug ui open')
    map("<Leader>due", dap_ui.eval, 'eval')

    vim.keymap.set({ "n", "v" }, "<Leader>dh",
        function() require 'dap.ui.widgets'.hover() end,
        { desc = '[DAP] Debug hover' })
    vim.keymap.set({ "n", "v" }, "<Leader>dp",
        function() require 'dap.ui.widgets'.preview() end,
        { desc = '[DAP] Debug preview' })
    vim.keymap.set({ "n", "v" }, "<Leader>dF",
        function() require 'dap.ui.widgets'.frames() end,
        { desc = '[DAP] Debug frames' })
    vim.keymap.set({ "n", "v" }, "<Leader>ds",
        function() require 'dap.ui.widgets'.scopes() end,
        { desc = '[DAP] Debug scopes' })

    -- also useful events are: event_terminated, event_exited
    dap.listeners.after.event_initialized["dapui_config"] = function()
        dap_ui.open()
    end
end

-- Requirements:
-- debugpy, pytest
local has_dap_python, dap_python = pcall(require, "dap-python")
if has_dap_python then
    local python_path = vim.fn.exepath('python')
    if vim.env.LOCAL_PYTHONPATH then python_path = vim.env.LOCAL_PYTHONPATH end
    vim.g.python3_host_prog = python_path
    dap_python.setup(vim.g.python3_host_prog)
    dap_python.test_runner = 'pytest'

    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'SLP Flask App',
        module = 'flask',
        env = {
            FLASK_APP = 'wsgi.py',
            FLASK_ENV = 'development',
            FLASK_DEBUG = '0'
        },
        args = { 'run', '--no-debugger', '--host=0.0.0.0', '--port=45120' },
        console = 'integratedTerminal',
        cwd = vim.fn.getcwd(),
        jinja = true
    })

    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        module = 'celery',
        name = 'SLP Celery Workers',
        args = {
            "--app=wsgi.celery", "worker", "--concurrency=1",
            "--loglevel=DEBUG", "--queues=linkedin_default", "-B"
        },
        gevent = true,
        console = 'integratedTerminal',
        cwd = vim.fn.getcwd(),
        env = {
            CELERY_TASK_ALWAYS_EAGER = 'True',
            AUTH_DEV = "KEYCLOAK_AUTH_DISABLED",
            LOG_NAME = "tasks",
            GEVENT_SUPPORT = 'True'
        }
    })
end

local lldb_path = vim.env.LLDB_VSCODE_DEBUGGER_PATH
if lldb_path then
    dap.adapters.lldb = {
        type = 'executable',
        command = lldb_path,
        name = 'lldb'
    }
    dap.configurations.cpp = {
        {
            name = 'Launch',
            type = 'lldb',
            request = 'launch',
            program = function()
                return vim.fn.input('Path to executable: ',
                    vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {}

            -- 💀
            -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
            --
            --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
            --
            -- Otherwise you might get the following error:
            --
            --    Error on launch: Failed to attach to the target process
            --
            -- But you should be aware of the implications:
            -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
            -- runInTerminal = false,
        }
    }

    -- If you want to use this for Rust and C, add something like this:
    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = dap.configurations.cpp
end


-- JS debugging configuration

require("dap-vscode-js").setup({
    debugger_path = vim.fn.exepath("js-debug"),
    adapters = {
        'chrome', 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal',
        'pwa-extensionHost', 'node', 'chrome'
    }
})

local js_based_languages = { "typescript", "javascript", "typescriptreact" }

local adaptre_settings = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
        command = 'js-debug',
        args = { '${port}' },
    }
}

dap.adapters['pwa-node'] = adaptre_settings
dap.adapters['pwa-chrome'] = adaptre_settings

for _, language in ipairs(js_based_languages) do
    require("dap").configurations[language] = {
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
        }, {
        type = "pwa-node",
        request = "attach",
        name = "Attach to process",
        processId = require 'dap.utils'.pick_process,
        cwd = "${workspaceFolder}"
    }, {
        type = "pwa-chrome",
        request = "launch",
        name = "Start Chrome with \"localhost\"",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
        runtimeExecutable = vim.fn.exepath("google-chrome"),
        runtimeArgs = { "--remote-debugging-port=9222" }
    }, {
        type = "pwa-chrome",
        request = "attach",
        name = "Attach Chrome to debug client side code",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
        port = 9222,
    }, {
        -- use nvim-dap-vscode-js's pwa-chrome debug adapter
        type = "pwa-chrome",
        request = "launch",
        -- name of the debug action
        name = "Launch Chrome to debug client side code",
        -- default vite dev server url
        url = "http://localhost:3000",
        -- for TypeScript/Svelte
        sourceMaps = true,
        webRoot = "${workspaceFolder}/src",
        protocol = "inspector",
        port = 9222,
        -- skip files from vite's hmr
        skipFiles = {
            "**/node_modules/**/*", "**/@vite/*", "**/src/client/*",
            "**/src/*"
        },
        runtimeExecutable = vim.fn.exepath("brave"),
        runtimeArgs = { "--remote-debugging-port=9222" }
    }, {
        name = 'Next.js: debug server-side',
        type = 'pwa-node',
        request = 'attach',
        port = 9231,
        skipFiles = { '<node_internals>/**', 'node_modules/**' },
        cwd = '${workspaceFolder}',
    }, {
        name = 'Next.js: debug client-side',
        type = 'pwa-chrome',
        request = 'launch',
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
        sourceMaps = true,     -- https://github.com/vercel/next.js/issues/56702#issuecomment-1913443304
        sourceMapPathOverrides = {
            ['webpack://_N_E/*'] = '${webRoot}/*',
        },
        runtimeExecutable = vim.fn.exepath("google-chrome"),
        runtimeArgs = { "--remote-debugging-port=9222" }
    }
    }
end

-- -- C configuration
-- -- lldb-vscode is part of the lldb/llvm package
-- -- check if lldb is available
-- if vim.fn.executable("lldb-vscode") == 1 then
--   dap.adapters.c = {
--       name = "lldb",
--       type = "executable",
--       attach = {
--           pidProperty = "pid",
--           pidSelect = "ask",
--       },
--       command = "lldb-vscode",
--       env = {
--           LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
--       },
--   }
--   dap.configurations.c = {
--       {
--           -- If you get an "Operation not permitted" error using this, try disabling YAMA:
--           --  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
--           --
--           -- Careful, don't try to attach to the neovim instance that runs *this*
--           name = "Fancy attach",
--           type = "c",
--           request = "attach",
--           pid = function()
--               local output = vim.fn.system { "ps", "a" }
--               local lines = vim.split(output, "\n")
--               local procs = {}
--               for _, line in pairs(lines) do
--                   -- output format
--                   --    " 107021 pts/4    Ss     0:00 /bin/zsh <args>"
--                   local parts = vim.fn.split(vim.fn.trim(line), " \\+")
--                   local pid = parts[1]
--                   local name = table.concat({ unpack(parts, 5) }, " ")
--                   if pid and pid ~= "PID" then
--                       pid = tonumber(pid)
--                       if pid ~= vim.fn.getpid() then
--                           table.insert(procs, { pid = pid, name = name })
--                       end
--                   end
--               end
--               local choices = { "Select process" }
--               for i, proc in ipairs(procs) do
--                   table.insert(choices,
--                       string.format("%d: pid=%d name=%s", i, proc.pid, proc.name))
--               end
--               -- Would be cool to have a fancier selection, but needs to be sync :/
--               -- Should nvim-dap handle coroutine results?
--               local choice = vim.fn.inputlist(choices)
--               if choice < 1 or choice > #procs then
--                   return nil
--               end
--               return procs[choice].pid
--           end,
--           args = {},
--       },
--       --[[
--     {
--       "type": "gdb",
--       "request": "attach",
--       "name": "Attach to gdbserver",
--       "executable": "<path to the elf/exe file relativ to workspace root in order to load the symbols>",
--       "target": "X.X.X.X:9999",
--       "remote": true,
--       "cwd": "${workspaceRoot}",
--       "gdbpath": "path/to/your/gdb",
--       "autorun": [
--               "any gdb commands to initiate your environment, if it is needed"
--           ]
--   }
--     --]]
-- }
--
-- end
--
--
-- dap.configurations.rust = {
--     {
--         name = "Launch",
--         type = "lldb",
--         request = "launch",
--         program = function()
--             return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/",
--                 "file")
--         end,
--         cwd = "${workspaceFolder}",
--         stopOnEntry = false,
--         args = {},
--         -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
--         --
--         --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
--         --
--         -- Otherwise you might get the following error:
--         --
--         --    Error on launch: Failed to attach to the target process
--         --
--         -- But you should be aware of the implications:
--         -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
--         runInTerminal = false,
--     },
-- }
--
--
-- -- Configure dap to use vscode-cpptools
-- -- https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)
-- dap.adapters.cppdbg = {
--     id = 'cppdbg',
--     type = 'executable',
--     command = 'OpenDebugAD7',
-- }
--
-- dap.configurations.cpp = {
--     {
--         name = "Handmade Hero",
--         type = "cppdbg",
--         request = "launch",
--         program = function()
--             return vim.fn.expand(
--                 '~/Projects/main/handmadehero/build/linux_handmade')
--         end,
--         cwd = '${workspaceFolder}',
--         stopAtEntry = true,
--     },
-- }
--
