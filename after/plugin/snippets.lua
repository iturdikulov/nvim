local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmta = require("luasnip.extras.fmt").fmta

local calculate_comment_string = require("Comment.ft").calculate
local utils = require("Comment.utils")

ls.config.setup({
    -- This tells LuaSnip to remember to keep around the last snippet.
    -- You can jump back into it even if you move outside of the selection
    history = false,

    -- This one is cool cause if you have dynamic snippets, it updates as you type!
    updateevents = "TextChanged,TextChangedI",

    -- Autosnippets:
    enable_autosnippets = true,
})

-- <c-k> is my expansion key
-- this will expand the current item or jump to the next item within the snippet.
vim.keymap.set({ "i", "s" }, "<c-k>", function()
    if ls.jumpable(1) then
        ls.jump(1)
    end
end, { silent = true })

-- <c-j> is my jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
    if ls.jumpable(-1) then
        ls.jump(-1)
    end
end, { silent = true })

local get_cstring = function(ctype)
    local cstring = calculate_comment_string({ ctype = ctype, range = utils.get_region() }) or vim.bo.commentstring
    local left, right = utils.unwrap_cstr(cstring)
    return { left, right }
end

local todo_snippet_nodes = function(aliases, opts)
    local aliases_nodes = vim.tbl_map(function(alias)
        return i(nil, alias)
    end, aliases)

    local comment_node = fmta("<> <>: <>", {
        f(function()
            return get_cstring(opts.ctype)[1]
        end),
        c(1, aliases_nodes),
        i(0),
    })
    return comment_node
end

local todo_snippet = function(context, aliases, opts)
    opts = opts or {}
    aliases = type(aliases) == "string" and { aliases } or aliases
    context = context or {}
    if not context.trig then
        return error("context doesn't include a `trig` key which is mandatory", 2)
    end
    opts.ctype = opts.ctype or 1
    local alias_string = table.concat(aliases, "|")
    context.name = context.name or (alias_string .. " comment")
    context.dscr = context.dscr or (alias_string .. " comment with a signature-mark")
    context.docstring = context.docstring or (" {1:" .. alias_string .. "}: {3} <{2:mark}>{0} ")
    local comment_node = todo_snippet_nodes(aliases, opts)
    return s(context, comment_node, opts)
end

local todo_snippet_specs = {
    { { trig = "todo" },  { "TODO", "NEXT" } },
    { { trig = "fix" },   { "FIX", "BUG", "ISSUE" } },
    { { trig = "warn" },  { "WARN", "WARNING" } },
    { { trig = "note" },  { "NOTE", "INFO" } },
    { { trig = "todob" }, "TODO",                    { ctype = 2 } },
    { { trig = "fixb" },  { "FIX", "BUG", "ISSUE" }, { ctype = 2 } },
    { { trig = "warnb" }, { "WARN", "WARNING" },     { ctype = 2 } },
    { { trig = "noteb" }, { "NOTE", "INFO" },        { ctype = 2 } },
}

local todo_comment_snippets = {}
for _, v in ipairs(todo_snippet_specs) do
    table.insert(todo_comment_snippets, todo_snippet(v[1], v[2], v[3]))
end

ls.add_snippets("all", todo_comment_snippets, { type = "snippets", key = "todo_comments" })

require("luasnip.loaders.from_vscode").load({
    paths = { vim.fn.stdpath("config") .. "/snippets" },
})

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_snipmate").lazy_load()
require("luasnip.loaders.from_lua").lazy_load()
