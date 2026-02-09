return {
	"NickvanDyke/opencode.nvim",
	config = function()
		-- Recommended/example keymaps.
		vim.keymap.set({ "n", "x" }, "<C-a><C-a>", function()
			require("opencode").ask("@this: ", { submit = true })
		end, { desc = "Ask opencode" })

		vim.keymap.set({ "n", "t" }, "<C-a>t", function()
			require("opencode").toggle()
		end, { desc = "Toggle opencode" })

		vim.keymap.set({ "n", "t" }, "<C-a><C-t>", function()
			require("opencode").toggle()
		end, { desc = "Toggle opencode" })

		vim.keymap.set({ "n", "x" }, "<C-a>x", function()
			require("opencode").select()
		end, { desc = "Execute opencode action…" })

		vim.keymap.set("n", "<M-u>", function()
			require("opencode").command("session.half.page.up")
		end, { desc = "opencode half page up" })

		vim.keymap.set("n", "<M-d>", function()
			require("opencode").command("session.half.page.down")
		end, { desc = "opencode half page down" })

		vim.keymap.set({ "n", "x" }, "go", function()
			return require("opencode").operator("@this ")
		end, { expr = true, desc = "Add range to opencode" })
		vim.keymap.set("n", "goo", function()
			return require("opencode").operator("@this ") .. "_"
		end, { expr = true, desc = "Add line to opencode" })

		-- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o".
		vim.keymap.set(
			"n",
			"+",
			"<C-a>",
			{ desc = "Increment", noremap = true }
		)
		vim.keymap.set(
			"n",
			"-",
			"<C-x>",
			{ desc = "Decrement", noremap = true }
		)
	end,
}
