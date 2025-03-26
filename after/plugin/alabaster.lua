vim.cmd("colorscheme alabaster")

-- Customize theme
vim.api.nvim_set_hl(0,'ColorColumn',{ bg='#30363f'})
vim.api.nvim_set_hl(0,'CopilotAnnotation',{ fg='#9d9c9c'})
vim.api.nvim_set_hl(0,'CopilotSuggestion',{ fg='#9d9c9c'})

-- Visual selection
vim.api.nvim_set_hl(0,'Visual',{ bg = '#333444'})

-- Express line
vim.api.nvim_set_hl(0,'ElInsert',{ fg='black', bg='yellow'})

-- Transparent background
vim.api.nvim_set_hl(0, 'Normal', { bg='NONE'})
vim.api.nvim_set_hl(0, 'NonText', { bg='NONE', fg='#444a52'})

-- Configure diff highlights
vim.api.nvim_set_hl(0, 'DiffText',  { fg = "#341a00", bg = "#3F0001" })
vim.api.nvim_set_hl(0, 'DiffAdd',  { fg = "#56d364", bg = "#244032" })
