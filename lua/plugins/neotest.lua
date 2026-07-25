return {
	"nvim-neotest/neotest",
	config = function()
		local neotest = require("neotest")
		local cwd = vim.fn.getcwd()
		local is_az = vim.fn.isdirectory(cwd .. "/packages/ltms-backend") == 1
		local workflow_bin = cwd .. "/docker/workflow/bin"

		local adapters = {}

		if is_az and vim.fn.executable(workflow_bin .. "/ltms-python") == 1 then
			table.insert(
				adapters,
				require("neotest-python")({
					python = workflow_bin .. "/ltms-python",
					runner = "pytest",
					args = { "--log-level", "DEBUG", "--capture", "tee-sys" },
					-- Discover under packages/ltms-backend when editing from monorepo root
					is_test_file = function(file_path)
						return file_path:match("packages/ltms%-backend/.+test.+" )
							or file_path:match("packages/ltms%-backend/tests/")
					end,
				})
			)
		else
			table.insert(
				adapters,
				require("neotest-python")({
					args = { "--log-level", "DEBUG", "--capture", "tee-sys" },
				})
			)
		end

		local ok_pw, playwright = pcall(require, "neotest-playwright")
		if ok_pw then
			local pw_opts = {
				persist_project_selection = true,
				enable_dynamic_test_discovery = true,
			}
			if is_az and vim.fn.executable(workflow_bin .. "/ltms-playwright") == 1 then
				pw_opts.get_playwright_binary = function()
					return workflow_bin .. "/ltms-playwright"
				end
				pw_opts.get_playwright_config = function()
					return cwd
						.. "/packages/ltms-frontend/tests/e2e/playwright.config.js"
				end
			end
			table.insert(adapters, playwright.adapter({ options = pw_opts }))
		end

		neotest.setup({
			adapters = adapters,
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
		"thenbe/neotest-playwright",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
}
