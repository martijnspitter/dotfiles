-- ============================================================================
-- PLUGINS (vim.pack)
-- ============================================================================
vim.pack.add({
    "https://www.github.com/lewis6991/gitsigns.nvim",
    "https://www.github.com/echasnovski/mini.nvim",
    "https://www.github.com/nvim-tree/nvim-tree.lua",
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
    },
    -- Language Server Protocols
    "https://www.github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/creativenull/efmls-configs-nvim",
    "https://github.com/obsidian-nvim/obsidian.nvim",
    "https://github.com/github/copilot.vim",
    "https://codeberg.org/andyg/leap.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/folke/todo-comments.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "https://github.com/rafamadriz/friendly-snippets",
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/catppuccin/nvim",
})

-- ============================================================================
-- PLUGIN CONFIGS
-- ============================================================================

-- ============================================================================
-- TREE SITTER
-- ============================================================================
local setup_treesitter = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})

    local ensure_installed = {
        "vim",
        "vimdoc",
        "rust",
        "go",
        "html",
        "css",
        "javascript",
        "json",
        "lua",
        "markdown",
        "python",
        "typescript",
        "vue",
        "svelte",
        "bash",
    }

    local config = require("nvim-treesitter.config")

    local already_installed = config.get_installed()
    local parsers_to_install = {}

    for _, parser in ipairs(ensure_installed) do
        if not vim.tbl_contains(already_installed, parser) then
            table.insert(parsers_to_install, parser)
        end
    end

    if #parsers_to_install > 0 then
        treesitter.install(parsers_to_install)
    end

    local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
                vim.treesitter.start(args.buf)
            end
        end,
    })
end

setup_treesitter()

-- ============================================================================
-- LEAP
-- ============================================================================
vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward)', { desc = 'Leap forward' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', '<Plug>(leap-backward)', { desc = 'Leap backward' })
vim.keymap.set({ 'n', 'x', 'o' }, 'gs', '<Plug>(leap-from-window)', { desc = 'Leap from window' })

-- ============================================================================
-- COPILOT
-- ============================================================================
vim.g.copilot_no_tab_map = true
vim.keymap.set('i', '<C-y>', 'copilot#Accept("\\<CR>")', {
    expr = true,
    replace_keycodes = false,
    desc = "Accept Copilot suggestion"
})
vim.keymap.set('i', '<C-]>', '<Plug>(copilot-dismiss)', { desc = "Dismiss Copilot" })
vim.keymap.set('i', '<M-]>', '<Plug>(copilot-suggest)', { desc = "Trigger Copilot" })

-- ============================================================================
-- OBSIDIAN
-- ============================================================================
local function setup_obsidian()
    require("obsidian").setup({
        legacy_commands = false,
        workspaces = { { name = "Second Brain", path = "~/obsidian-vault" } },
        picker = { name = "telescope" },
        new_notes_location = 'notes',
        ui = {
            enable = true,
            checkboxes = {
                [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                ["x"] = { char = "", hl_group = "ObsidianDone" },
                [">"] = { char = "", hl_group = "ObsidianRightArrow" },
                ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
            },
            external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
        },
        checkbox = {
            enabled = true,
            create_new = true,
            order = { " ", "x", ">", "~" },
        },
        daily_notes = {
            enabled = true,
            folder = 'timeline',
            template = 'daily-note-nvim.md',
        },
        frontmatter = {
            enable = true,
            func = function(note)
                -- Add the title of the note as an alias.
                if note.title then
                    note:add_alias(note.title)
                end

                local out = {
                    id = note.id,
                    created = os.date '%Y-%m-%d %H:%M:%S',
                    updated = os.date '%Y-%m-%d %H:%M:%S',
                }

                -- Check if this is a daily note based on:
                -- 1. Existing type in metadata
                -- 2. Note is in the timeline folder
                -- 3. Title contains current or next year
                local is_daily_note = false

                if note.metadata and note.metadata.type == '#daily-note' then
                    is_daily_note = true
                elseif note.path and string.find(tostring(note.path), 'timeline') then
                    is_daily_note = true
                elseif note.title then
                    local current_year = os.date '%Y'
                    local next_year = tostring(tonumber(current_year) + 1)
                    is_daily_note = string.find(note.title, current_year) or string.find(note.title, next_year)
                end

                if is_daily_note then
                    out.year = '[[' .. os.date('%Y') .. ']]'
                    out.week = '[[' .. os.date('%G-W%V') .. ']]'
                    out.type = '#daily-note'
                else
                    out.type = '#note'
                end

                -- Add aliases if they exist
                if note.aliases and #note.aliases > 0 then
                    out.aliases = note.aliases
                end

                -- Add tags if they exist
                if note.tags and #note.tags > 0 then
                    out.tags = note.tags
                end

                -- `note.metadata` contains any manually added fields in the frontmatter.
                -- So here we just make sure those fields are kept in the frontmatter.
                -- This preserves the created date and any other manually added fields.
                if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                    for k, v in pairs(note.metadata) do
                        -- Don't override updated timestamp, but preserve created
                        if k ~= 'updated' then
                            out[k] = v
                        end
                    end
                end

                return out
            end,
        },

        templates = {
            enabled = true,
            folder = "templates",
            date_format = '%Y-%m-%d',
            time_format = '%H:%M',
            default_template = "default.md",
            substitutions = {
                id = function()
                    return vim.fn.system('uuidgen'):gsub('%s', '')
                end,
                created = function()
                    return os.date '%Y-%m-%d %H:%M:%S'
                end,
                updated = function()
                    return os.date '%Y-%m-%d %H:%M:%S'
                end,
                year = function()
                    return os.date '[[%Y]]'
                end,
                week = function()
                    return os.date '[[%G-W%V]]'
                end,
            },
        },
    })

    -- Create new note with default template
    vim.keymap.set("n", "<leader>on", function()
        local obsidian = require("obsidian").get_client()
        local title = vim.fn.input("Note title: ")
        if title == "" then return end

        local note = obsidian:create_note({ title = title })
        vim.cmd("edit " .. tostring(note.path))

        -- Check if template exists before applying
        local template_path = vim.fn.expand("~/obsidian-vault/templates/default-note-nvim.md")
        if vim.fn.filereadable(template_path) == 1 then
            vim.defer_fn(function()
                vim.cmd("ObsidianTemplate default-note-nvim.md")
            end, 150)
        end
    end, { desc = '[O]bsidian [N]ew note' })
    vim.keymap.set("n", "<leader>ot", '<cmd>Obsidian new_from_template<CR>', { desc = '[O]bsidian [T]emplate' })
    vim.keymap.set("n", "<leader>of", "<cmd>Obsidian quick_switch<cr>", { desc = "[O]bsidian [F]ind note" })
    vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "[O]bsidian [S]earch" })
    vim.keymap.set("n", "<leader>od", "<cmd>Obsidian today<cr>", { desc = "[O]bsidian [D]aily note" })
end

setup_obsidian()

-- ============================================================================
-- FILE EXPLORER
-- ============================================================================
require("nvim-tree").setup({
    view = {
        width = 35,
    },
    filters = {
        dotfiles = false,
        git_ignored = false,
    },
    renderer = {
        group_empty = true,
    },
    actions = {
        open_file = {
            quit_on_open = true,
            window_picker = {
                enable = false,
            },
        }
    },
})
vim.keymap.set("n", "<C-g>", function()
    require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeSignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = "#2a2a2a", bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })

-- ============================================================================
-- Todo Comments
-- ============================================================================
require("todo-comments").setup({})

-- ============================================================================
-- Telescope
-- ============================================================================
require("telescope").setup({
    defaults = {
        get_icon = require("mini.icons").get,
    },
    pickers = {
        find_files = {
            hidden = true,
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
        }
    }
})

-- Load fzf native extension for better performance
pcall(require('telescope').load_extension, 'fzf')

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>td', ':TodoTelescope<CR>')
vim.keymap.set('n', '<leader>sn', function()
    builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[S]earch [N]eovim files' })

-- ============================================================================
-- MINI
-- ============================================================================
require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.move").setup({})
require("mini.surround").setup({})
require("mini.cursorword").setup({})
require("mini.indentscope").setup({})
require("mini.pairs").setup({})
require("mini.trailspace").setup({})
require("mini.bufremove").setup({})
require("mini.notify").setup({})
require("mini.icons").setup({})
require("mini.cmdline").setup({})

-- ============================================================================
-- GITSIGNS
-- ============================================================================
require("gitsigns").setup({
    signs = {
        add = { text = "\u{2590}" },          -- ▏
        change = { text = "\u{2590}" },       -- ▐
        delete = { text = "\u{2590}" },       -- ◦
        topdelete = { text = "\u{25e6}" },    -- ◦
        changedelete = { text = "\u{25cf}" }, -- ●
        untracked = { text = "\u{25cb}" },    -- ○
    },
    signcolumn = true,
    current_line_blame = false,
})

-- ============================================================================
-- MASON
-- ============================================================================
require("mason").setup({})

vim.keymap.set("n", "]h", function()
    require("gitsigns").nav_hunk("next")
end, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", function()
    require("gitsigns").nav_hunk("prev")
end, { desc = "Previous git hunk" })
vim.keymap.set("n", "<leader>hs", function()
    require("gitsigns").stage_hunk()
end, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", function()
    require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>hp", function()
    require("gitsigns").preview_hunk()
end, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>hb", function()
    require("gitsigns").blame_line({ full = true })
end, { desc = "Blame line" })
vim.keymap.set("n", "<leader>hB", function()
    require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle inline blame" })
vim.keymap.set("n", "<leader>hd", function()
    require("gitsigns").diffthis()
end, { desc = "Diff this" })

-- ============================================================================
-- Completion
-- ============================================================================
local diagnostic_signs = {
    Error = " ",
    Warn = " ",
    Hint = "",
    Info = "",
}

vim.diagnostic.config({
    virtual_text = { prefix = "●", spacing = 4 },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
            [vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
            [vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
            [vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
        },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
        focusable = false,
        style = "minimal",
    },
})

do
    local orig = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or "rounded"
        return orig(contents, syntax, opts, ...)
    end
end

local function lsp_on_attach(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
        return
    end

    local bufnr = ev.buf
    local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, noremap = true, desc = 'LSP: ' .. desc })
    end

    -- Jump to the definition of the word under your cursor.
    --  This is where a variable was first declared, or where a function is defined, etc.
    --  To jump back, press <C-t>.
    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

    -- Find references for the word under your cursor.
    map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

    -- Jump to the implementation of the word under your cursor.
    --  Useful when your language has ways of declaring types without an actual implementation.
    map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

    -- Jump to the type of the word under your cursor.
    --  Useful when you're not sure what type a variable is and you want to see
    --  the definition of its *type*, not where it was *defined*.
    map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

    -- Fuzzy find all the symbols in your current document.
    --  Symbols are things like variables, functions, types, etc.
    map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

    -- Fuzzy find all the symbols in your current workspace.
    --  Similar to document symbols, except searches over your entire project.

    map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    -- Opens a popup that displays documentation about the word under your cursor
    --  See `:help K` for why this keymap.
    map('K', vim.lsp.buf.hover, 'Hover Documentation')

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    if client and client.server_capabilities.documentHighlightProvider then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = ev.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = ev.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
        })
    end

    if client:supports_method("textDocument/codeAction", bufnr) then
        vim.keymap.set("n", "<leader>oi", function()
            vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" }, diagnostics = {} },
                apply = true,
                bufnr = bufnr,
            })
            vim.defer_fn(function()
                vim.lsp.buf.format({ bufnr = bufnr })
            end, 50)
        end, { buffer = bufnr, desc = "Organize Imports" })
    end
end

-- Module-scoped augroup: each config file owns a uniquely named group so that
-- re-sourcing one file (clear = true) never wipes another file's autocmds.
local augroup = vim.api.nvim_create_augroup("UserPacks", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
    vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

-- ============================================================================
-- Completion
-- ============================================================================
require("mini.completion").setup({
    lsp_completion = {
        auto_setup = true,
    }
})

--- mini snippets ---
local MiniSnippets = require("mini.snippets")

MiniSnippets.setup({
    snippets = {
        MiniSnippets.gen_loader.from_lang(), -- loads friendly-snippets
        MiniSnippets.gen_loader.from_file(vim.fn.stdpath("config") .. "/lua/snippets.lua"),
    },
})
MiniSnippets.start_lsp_server({ match = false })

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
        },
    },
})
vim.lsp.config("pyright", {})
vim.lsp.config("bashls", {})
vim.lsp.config("ts_ls", {})
vim.lsp.config("gopls", {})
vim.lsp.config("clangd", {})

-- Biome owns JS/TS/JSON formatting + import sorting + unused-import removal.
-- Filetypes are scoped here so Biome never competes with prettier (efm) on
-- css/html/vue/svelte. Project-local cmd + biome.json root detection come from
-- nvim-lspconfig's bundled default (prefers <root>/node_modules/.bin/biome and
-- only attaches when a biome.json/biome.jsonc is found upward).
vim.lsp.config("biome", {
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
    },
})

do
    local luacheck = require("efmls-configs.linters.luacheck")
    local stylua = require("efmls-configs.formatters.stylua")

    local flake8 = require("efmls-configs.linters.flake8")
    local black = require("efmls-configs.formatters.black")

    local prettier_d = require("efmls-configs.formatters.prettier_d")
    local eslint_d = require("efmls-configs.linters.eslint_d")

    local shellcheck = require("efmls-configs.linters.shellcheck")
    local shfmt = require("efmls-configs.formatters.shfmt")

    local cpplint = require("efmls-configs.linters.cpplint")
    local clangfmt = require("efmls-configs.formatters.clang_format")

    local go_revive = require("efmls-configs.linters.go_revive")
    local gofumpt = require("efmls-configs.formatters.gofumpt")

    vim.lsp.config("efm", {
        filetypes = {
            "c",
            "cpp",
            "css",
            "go",
            "html",
            "lua",
            "markdown",
            "python",
            "sh",
            "vue",
            "svelte",
        },
        init_options = { documentFormatting = true },
        settings = {
            languages = {
                c = { clangfmt, cpplint },
                go = { gofumpt, go_revive },
                cpp = { clangfmt, cpplint },
                css = { prettier_d },
                html = { prettier_d },
                lua = { luacheck, stylua },
                markdown = { prettier_d },
                python = { flake8, black },
                sh = { shellcheck, shfmt },
                vue = { eslint_d, prettier_d },
                svelte = { eslint_d, prettier_d },
            },
        },
    })
end

vim.lsp.enable({
    "lua_ls",
    "pyright",
    "bashls",
    "ts_ls",
    "gopls",
    "clangd",
    "efm",
    "biome",
})

-- ============================================================================
-- FLOATING TERMINAL
-- ============================================================================
vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function()
        if vim.v.event.status == 0 then
            vim.api.nvim_buf_delete(0, {})
        end
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
    end,
})

local terminal_state = { buf = nil, win = nil, is_open = false }

local function FloatingTerminal()
    if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
        vim.api.nvim_win_close(terminal_state.win, false)
        terminal_state.is_open = false
        return
    end

    if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
        terminal_state.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[terminal_state.buf].bufhidden = "hide"
    end

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    vim.wo[terminal_state.win].winblend = 0
    vim.wo[terminal_state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
    vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })

    local has_terminal = false
    local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
    for _, line in ipairs(lines) do
        if line ~= "" then
            has_terminal = true
            break
        end
    end
    if not has_terminal then
        vim.fn.termopen(os.getenv("SHELL"))
    end

    terminal_state.is_open = true
    vim.cmd("startinsert")

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = terminal_state.buf,
        callback = function()
            if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
                vim.api.nvim_win_close(terminal_state.win, false)
                terminal_state.is_open = false
            end
        end,
        once = true,
    })
end

vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
vim.keymap.set("t", "<C-\\><C-\\>", function()
    if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
        vim.api.nvim_win_close(terminal_state.win, false)
        terminal_state.is_open = false
    end
end, { noremap = true, silent = true, desc = "Close floating terminal" })
