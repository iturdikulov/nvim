-- TODO: convert to lua
vim.cmd [[
let g:zv_zeal_executable = has('win32')
            \ ? $ProgramFiles . '\Zeal\zeal.exe'
            \ : 'tmux-zeal-query'

let g:zv_file_types = {
            \   'help'                : 'vim',
            \   'javascript'          : 'javascript,nodejs',
            \   'css'                 : 'css',
            \   'html'                : 'html',
            \   'markdown'            : 'python,rust,go,javascript',
            \   'typescript'          : 'typescript,nodejs',
            \   'go'                  : 'go',
            \   'lua'                 : 'lua,neovim',
            \   'rust'                : 'rust',
            \   'python'              : 'python_3,numpy,pandas,sqlalchemy,flask',
            \   '\v^(G|g)ulpfile\.js' : 'gulp,javascript,nodejs',
            \   'gdscript'            : 'godot'
            \ }
]]

local map = function(mode, lhs, rhs, desc)
    if desc then desc = "[Zeavim] " .. desc end
    vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
end

vim.g.zv_disable_mapping = 1
vim.g.zv_keep_focus = 0
map("n", "gz", "<Plug>ZVOperator", "search operator in docset")
map("n", "gzz", "<Plug>Zeavim", "search in docset")
map("v", "gzz", "<Plug>ZVVisSelection", "search selection in docset")
map("n", "gZ", "<Plug>ZVKeyDocset", "customize key docset and search")
