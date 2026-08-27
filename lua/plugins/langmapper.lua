-- langmap (встроенные команды) + langmapper.nvim (кастомные маппинги).
-- hack_keymap / automapping дублируют vim.keymap.set и lazy keys на ru;
-- langmap нужен для dw/gg/ciw и т.п. — langmapper их не трогает.

local function escape(str)
	local escape_chars = [[;,."|\]]
	return vim.fn.escape(str, escape_chars)
end

-- Официальный пример из langmapper.nvim README — только буквы/скобки.
-- Пунктуацию (,./? и т.д.) добавлять нельзя: символы вроде "/" в ru_shift
-- перехватывают "/" на английской раскладке и ломают поиск.
local function setup_langmap()
	local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
	local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
	local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
	local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

	vim.opt.langmap = vim.fn.join({
		escape(ru_shift) .. ";" .. escape(en_shift),
		escape(ru) .. ";" .. escape(en),
	}, ",")
end

return {
	"Wansmer/langmapper.nvim",
	lazy = false,
	priority = 1,
	config = function()
		setup_langmap()

		local langmapper = require("langmapper")
		langmapper.setup({
			hack_keymap = true,
			layouts = {
				ru = { id = "ru" },
			},
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyDone",
			once = true,
			callback = function()
				langmapper.automapping({ global = true, buffer = false })
			end,
		})
	end,
}
