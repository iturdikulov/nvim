return {
    "L3MON4D3/LuaSnip",
    dependencies = {
        "numToStr/Comment.nvim", -- For custom TODO snippets
        "iturdikulov/friendly-snippets" -- My snippets collection
    },

    opts = {},
    config = function()
        local ls = require("luasnip")

        -- Basic keymap
        -- <c-j> is my expansion key
        -- this will expand the current item or jump to the next item within the snippet.
        vim.keymap.set({ "i", "s" }, "<c-j>", function()
            if ls.expand_or_jumpable() then
                ls.expand_or_jump()
            end
        end, { silent = true })

        -- <c-k> is my jump backwards key.
        -- this always moves to the previous item within the snippet
        vim.keymap.set({ "i", "s" }, "<c-k>", function()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end, { silent = true })

        vim.keymap.set({ "i", "s" }, "<C-E>", function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, { silent = true })

        -- Loaders
        require("luasnip.loaders.from_vscode").load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
        })
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load()

        -- Special TODO snippets
        local s = ls.snippet
        local i = ls.insert_node
        local f = ls.function_node
        local t = ls.text_node
        local fmta = require("luasnip.extras.fmt").fmta

        local calculate_comment_string = require("Comment.ft").calculate
        local utils = require("Comment.utils")

        local get_cstring = function(ctype)
            local cstring = calculate_comment_string({
                ctype = ctype,
                range = utils.get_region(),
            }) or vim.bo.commentstring
            local left, right = utils.unwrap_cstr(cstring)
            return { left, right }
        end

        local todo_snippet_nodes = function(alias, opts)
            local comment_node = fmta("<> <>: <>", {
                f(function()
                    return get_cstring(opts.ctype)[1]
                end),
                t(alias),
                i(0),
            })
            return comment_node
        end

        local todo_snippet = function(context, aliases, opts)
            opts = opts or {}
            aliases = type(aliases) == "string" and { aliases } or aliases
            context = context or {}
            if not context.trig then
                return error(
                    "context doesn't include a `trig` key which is mandatory",
                    2
                )
            end
            opts.ctype = opts.ctype or 1
            local alias_string = table.concat(aliases, "|")
            context.name = context.name or (alias_string .. " comment")
            context.dscr = context.dscr
                or (alias_string .. " comment with a signature-mark")
            context.docstring = context.docstring
                or (" {1:" .. alias_string .. "}: {3} <{2:mark}>{0} ")
            local comment_node = todo_snippet_nodes(aliases, opts)
            return s(context, comment_node, opts)
        end

        local todo_snippet_specs = {
            { { trig = "todo" }, "TODO"  },
            { { trig = "fix" },  "FIX"  },
            { { trig = "warn" }, "WARN"  },
            { { trig = "note" }, "NOTE"  },
            { { trig = "todob" }, "TODO", { ctype = 2 } },
            { { trig = "fixb" },  "FIX" , { ctype = 2 } },
            { { trig = "warnb" },  "WARN" , { ctype = 2 } },
            { { trig = "noteb" },  "NOTE" , { ctype = 2 } },
        }

        local todo_comment_snippets = {}
        for _, v in ipairs(todo_snippet_specs) do
            table.insert(todo_comment_snippets, todo_snippet(v[1], v[2], v[3]))
        end

        ls.add_snippets(
            "all",
            todo_comment_snippets,
            { type = "snippets", key = "todo_comments" }
        )
    end,
}
