require("config.lazy")
require("config.set")
require("config.remap")
require("config.spell")
require("config.checkbox")
if not require("config.platform").is_windows then
    require("config.gnupg")
end
require("config.utils")
vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/config/xxd.vimrc")
