-- ============================================================================
-- CUSTOM SNIPPETS
-- ============================================================================
-- Snippets for mini.snippets
-- Format: { prefix = "trigger", body = "text", desc = "description" }
-- Tabstops: $1, $2, etc. (use Tab to jump), $0 = final position
-- Placeholder: ${1:default text}

return {
    -- ========================================================================
    -- Global snippets (all filetypes)
    -- ========================================================================
    { prefix = "todo",  body = "TODO(martijn): $1",           desc = "Todo comment" },
    { prefix = "fixme", body = "FIXME: $1",                   desc = "Fixme comment" },
    { prefix = "note",  body = "NOTE: $1",                    desc = "Note comment" },
    { prefix = "hack",  body = "HACK: $1",                    desc = "Hack comment" },

    -- ========================================================================
    -- JavaScript/TypeScript
    -- ========================================================================
    { prefix = "log",       body = "console.log('$1:', $1);$0",                   desc = "Console log" },
    { prefix = "jlog",      body = "console.log('$1:', JSON.stringify($1));$0",   desc = "Console log simple" },
    { prefix = "kerror",    body = "console.kError('$1:', $1);$0",                desc = "Console error" },
    {
        prefix = "comblock",
        body = [[
// ===========================================================================
// ${1:Section}
// ===========================================================================
$0]],
        desc = "Comment Block",
    },
}
