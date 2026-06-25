-- ============================================================================
-- COMMANDS
-- ============================================================================

vim.api.nvim_create_user_command("PackAdd", function(opts)
    vim.pack.add(opts.fargs)
end, { nargs = "+", desc = "Add plugins (:PackAdd user/repo1 user/repo2)" })

-- Pack Delete and Update cmds are built-in on Nightly 0.13
vim.api.nvim_create_user_command("PackDel", function(opts)
    vim.pack.del(opts.fargs)
end, { nargs = "+", desc = "Delete plugins (:PackDel plugin1 plugin2)" })

vim.api.nvim_create_user_command("PackUpdate", function(opts)
    -- checks if any argument is passed
    if opts.args:match("%S") then
        -- update specific plugins
        local plugins = vim.split(opts.args, "%s+", { trimempty = true })
        -- update only specified plugins
        vim.pack.update(plugins)
    else
        -- update all
        vim.pack.update()
    end
end, { nargs = "*", desc = "Update all plugins or specific ones" })

-- Command to manually build telescope-fzf-native
vim.api.nvim_create_user_command("TelescopeFzfBuild", function()
    local path = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
    if vim.fn.isdirectory(path) == 1 then
        vim.notify("Building telescope-fzf-native...")
        vim.fn.jobstart({ "make" }, {
            cwd = path,
            on_exit = function(_, code)
                if code == 0 then
                    vim.notify("telescope-fzf-native built successfully! Restart Neovim.", vim.log.levels.INFO)
                else
                    vim.notify("Failed to build telescope-fzf-native. Code: " .. code, vim.log.levels.ERROR)
                end
            end,
        })
    else
        vim.notify("telescope-fzf-native.nvim not found at: " .. path, vim.log.levels.ERROR)
    end
end, { desc = "Build telescope-fzf-native manually" })

-- ============================================================================
-- AUTOCMDS
-- ============================================================================

-- Module-scoped augroup: each config file owns a uniquely named group so that
-- re-sourcing one file (clear = true) never wipes another file's autocmds.
local augroup = vim.api.nvim_create_augroup("UserCommands", { clear = true })

-- Synchronously request and apply LSP "source" code actions (e.g. organize
-- imports, fix-all) so the edits land BEFORE the buffer is written. Using the
-- async vim.lsp.buf.code_action({ apply = true }) inside BufWritePre would apply
-- edits only after the write, leaving the saved file unchanged.
local function apply_source_actions(bufnr, client, action_ids)
    for _, id in ipairs(action_ids) do
        local params = {
            textDocument = vim.lsp.util.make_text_document_params(bufnr),
            range = {
                start = { line = 0, character = 0 },
                ["end"] = { line = 0, character = 0 },
            },
            context = { only = { id }, diagnostics = {} },
        }
        local resp = client:request_sync("textDocument/codeAction", params, 1500, bufnr)
        for _, action in ipairs((resp or {}).result or {}) do
            if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
            if type(action.command) == "table" then
                client:request_sync("workspace/executeCommand", action.command, 1500, bufnr)
            end
        end
    end
end

-- Format on save (ONLY real file buffers, ONLY when biome or efm is attached)
vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = {
        "*.lua",
        "*.py",
        "*.go",
        "*.js",
        "*.jsx",
        "*.ts",
        "*.tsx",
        "*.json",
        "*.css",
        "*.scss",
        "*.html",
        "*.sh",
        "*.bash",
        "*.zsh",
        "*.c",
        "*.cpp",
        "*.h",
        "*.hpp",
        "*.md",
    },
    callback = function(args)
        -- avoid formatting non-file buffers (helps prevent weird write prompts)
        if vim.bo[args.buf].buftype ~= "" then
            return
        end
        if not vim.bo[args.buf].modifiable then
            return
        end
        if vim.api.nvim_buf_get_name(args.buf) == "" then
            return
        end

        local biome, efm
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
            if c.name == "biome" then
                biome = c
            elseif c.name == "efm" then
                efm = c
            end
        end

        if biome then
            -- Sort imports + apply safe fixes (incl. unused-import removal when
            -- the rule is enabled in biome.json), then format.
            apply_source_actions(args.buf, biome, {
                "source.organizeImports.biome",
                "source.fixAll.biome",
            })
            pcall(vim.lsp.buf.format, {
                bufnr = args.buf,
                timeout_ms = 2000,
                filter = function(c)
                    return c.name == "biome"
                end,
            })
        elseif efm then
            pcall(vim.lsp.buf.format, {
                bufnr = args.buf,
                timeout_ms = 2000,
                filter = function(c)
                    return c.name == "efm"
                end,
            })
        end
    end,
})

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    callback = function()
        vim.hl.on_yank()
    end,
})

-- return to last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    desc = "Restore last cursor position",
    callback = function()
        if vim.o.diff then -- except in diff mode
            return
        end

        local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- {line, col}
        local last_line = vim.api.nvim_buf_line_count(0)

        local row = last_pos[1]
        if row < 1 or row > last_line then
            return
        end

        pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
    end,
})

-- wrap, linebreak and spellcheck on markdown and text files
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "markdown", "text", "gitcommit" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.spell = true
        vim.opt.spelllang = 'en_us'
    end,
})
