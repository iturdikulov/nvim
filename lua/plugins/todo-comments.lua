return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("todo-comments").setup({
			signs = false,
			highlight = {
				comments_only = false, -- uses treesitter to match keywords in comments only
				exclude = {}, -- list of file types to exclude highlighting
			},
			--        -- Colors from https://rosepinetheme.com/palette/ingredients/
			keywords = {
				DONE = {
					color = "#908caa",
					alt = { "CLOSED", "FIXED" },
				},
				CRITICAL = { color = "error" },
				WAITING = { color = "#31748f" },
				DELEGATED = { color = "error" },
				CANCELED = { color = "#403d52" },
				REPEAT = { color = "#ebbcba" },
				PROJECT = { color = "warning" },
			},
		})
		vim.keymap.set("n", "]t", function()
			require("todo-comments").jump_next({
				keywords = { "ERROR", "WARNING", "WARN" },
			})
		end, { desc = "Next error/warning todo comment" })

		vim.keymap.set("n", "]T", function()
			require("todo-comments").jump_next()
		end, { desc = "Next todo comment" })

		vim.keymap.set("n", "[t", function()
			require("todo-comments").jump_prev()
		end, { desc = "Previous todo comment" })

		vim.keymap.set(
			"n",
			"<leader>ft",
			":TodoTelescope keywords=TODO,NOW<CR>",
			{ desc = "Show todo list" }
		)

		local function toggle_todo_line(line)
			-- GUARD: Ignore empty lines or lines with only whitespace
			if line:match("^%s*$") then
				return line
			end

			local word_pairs = {
				{ "TODO", "DONE" },
				{ "CRITICAL", "DONE" },
				{ "WARN", "DONE" },
			}

			-- GUARD: If line starts with "- UPPERCASE_WORD" (and it's NOT in
			-- word_pairs, this pattern looks for a dash followed by 1+ uppercase letters
			local _, upper_word = line:match("^(%s*%-%s*)(%w+)")
			if
				upper_word
				and not vim.tbl_contains(
					vim.tbl_map(function(pair)
						return pair[1]
					end, word_pairs),
					upper_word
				)
				and (
					upper_word == upper_word:upper()
					and not tonumber(upper_word)
				)
			then
				-- verify upper_word isn't number
				return line
			end

			local new_line = line

			--  Toggle Checkboxes: - [ ] <-> - [x]
			if line:match("^%s*%- %[ %]") then
				new_line = line:gsub("^(%s*)%- %[ %]", "%1- [x]", 1)
			elseif line:match("^%s*%- %[x%]") then
				new_line = line:gsub("^(%s)*%- %[x%]", "%1- [ ]", 1)
			-- Toggle Keywords: - PAIRS: <-> - DONE:
			elseif line:match("^%s*%- (%w+)") then
				for _, pair in ipairs(word_pairs) do
					local from, to = pair[1], pair[2]
					if line:match("^%s*%- " .. from) then
						new_line = line:gsub(
							"^(%s*)%- " .. from,
							"%1- " .. to .. ":",
							1
						)
						break
					elseif line:match("^%s*%- " .. to) then
						new_line = line:gsub(
							"^(%s*)%- " .. to .. ":",
							"%1- " .. from,
							1
						)
						break
					end
				end
			-- If line doesn't start with "-", add "- TODO: "
			elseif not line:match("^%s*%-") then
				new_line = line:gsub("^(%s*)(.*)", "%1- TODO: %2", 1)
			-- If line starts with "-" but has no marker, add "TODO:"
			else
				new_line = line:gsub("^(%s*%-)%s*", "%1 TODO: ", 1)
			end

			vim.api.nvim_set_current_line(new_line)

			return new_line
		end

		vim.keymap.set({ "n", "v" }, "<leader>td", function()
			local mode = vim.api.nvim_get_mode().mode
			local start_line, end_line

			if mode:match("[vV]") then
				start_line = vim.fn.line("v")
				end_line = vim.fn.line(".")
				if start_line > end_line then
					start_line, end_line = end_line, start_line
				end
			else
				start_line = vim.api.nvim_win_get_cursor(0)[1]
				end_line = start_line
			end

			local lines =
				vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
			local updated_lines = {}

			for _, line in ipairs(lines) do
				table.insert(updated_lines, toggle_todo_line(line))
			end

			vim.api.nvim_buf_set_lines(
				0,
				start_line - 1,
				end_line,
				false,
				updated_lines
			)

			if mode:match("[vV]") then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
					"n",
					true
				)
			end
		end, { desc = "Toggle TODO item(s)" })

		vim.keymap.set("n", "<leader>tD", function()
			local buf = vim.api.nvim_get_current_buf()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

			local filename = vim.api.nvim_buf_get_name(buf)
			if filename == "" then
				print("File must be saved before archiving DONE items.")
				return
			end

			local dir = vim.fn.fnamemodify(filename, ":h")
			local name = vim.fn.fnamemodify(filename, ":t:r")
			local ext = vim.fn.fnamemodify(filename, ":e")

			local archive_path =
				string.format("%s/%s_archive.%s", dir, name, ext)

			local remaining = {}
			local archived = {}

			for _, line in ipairs(lines) do
				if line:match("DONE:") then
					table.insert(archived, line)
				else
					table.insert(remaining, line)
				end
			end

			-- Replace buffer with remaining (non-DONE) lines
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, remaining)

			-- Append archived lines to archive file
			local f = io.open(archive_path, "a+")
			if f then
				for _, l in ipairs(archived) do
					f:write(l .. "\n")
				end
				f:close()
				vim.notify("Archived DONE items → " .. archive_path)
			else
				vim.notify("Could not open or create archive file.")
			end
		end, { desc = "Archive DONE: items" })
	end,
}
