-- ============================================================================
-- KEYMAPS
-- ============================================================================

vim.g.mapleader = " "      -- space for leader
vim.g.maplocalleader = " " -- space for localleader


-- better movement in wrapped text
vim.keymap.set("n", "j", function()
    return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
vim.keymap.set("n", "k", function()
    return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

-- Clear highlights on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setqflist, { desc = 'Send all [D]iagnostics to [Q]uickfix' })

-- Navigate between buffers
vim.keymap.set('n', 'tl', ':bnext<CR>', { desc = 'Go to left buffer' })
vim.keymap.set('n', 'th', ':bprevious<CR>', { desc = 'Go to right buffer' })
vim.api.nvim_set_keymap('n', 'tk', ':blast<enter>', { noremap = false, desc = 'Go to last buffer' })
vim.api.nvim_set_keymap('n', 'tj', ':bfirst<enter>', { noremap = false, desc = 'Go to first buffer' })
vim.api.nvim_set_keymap('n', 'td', ':bdelete<enter>', { noremap = false, desc = 'Delete buffer' })
vim.api.nvim_set_keymap('n', 'ta', ':%bd|e#|bd#<enter>', { noremap = false, desc = 'Close all buffers except this one' })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- window management
vim.keymap.set('n', '<C-w>e', '<C-w>=', { desc = 'Make splits equal size' })
vim.keymap.set('n', '<C-w>q', '<cmd>close<CR>', { desc = 'Close current split' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Center buffer while navigating
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Center buffer while jumping up' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Center buffer while jumping down' })
vim.keymap.set('n', '{', '{zz', { desc = 'Center buffer while jumping to previous parenthesis' })
vim.keymap.set('n', '}', '}zz', { desc = 'Center buffer while jumping to next parenthesis' })
vim.keymap.set('n', 'N', 'Nzz', { desc = 'Jump to previous search result' })
vim.keymap.set('n', 'n', 'nzz', { desc = 'Jump to next search result' })
vim.keymap.set('n', 'G', 'Gzz', { desc = 'Go to the bottom of the file' })
vim.keymap.set('n', 'gg', 'ggzz', { desc = 'Go to the top of the file' })
vim.keymap.set('n', '<C-i>', '<C-i>zz', { desc = 'Jump to next location in jump list' })
vim.keymap.set('n', '<C-o>', '<C-o>zz', { desc = 'Jump to previous location in jump list' })
vim.keymap.set('n', '%', '%zz', { desc = 'Jump to matching parenthesis' })
vim.keymap.set('n', '*', '*zz', { desc = 'Search forwards for the word under the cursor' })
vim.keymap.set('n', '#', '#zz', { desc = 'Search backwards for the word under the cursor' })

-- Line Navigation
vim.keymap.set('n', 'L', '$', { desc = 'Move to the end of the line' })
vim.keymap.set('n', 'H', '0', { desc = 'Move to the start of the line' })

-- End Insert mode with jj
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'End Insert mode with jj' })

-- Press 'rw' for quick find/replace for the word under the cursor
vim.keymap.set('n', '<leader>rw', function()
    local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
    local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', false)
end)

-- Save the current file
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save the current file' })

-- These mappings control the size of splits (height/width)
vim.keymap.set('n', '<leader>ml', '<c-w>5<')
vim.keymap.set('n', '<leader>mh', '<c-w>5>')
vim.keymap.set('n', '<leader>mk', '<C-W>+')
vim.keymap.set('n', '<leader>mj', '<C-W>-')

-- Dismiss Noice Message
vim.keymap.set('n', '<leader>nd', '<cmd>NoiceDismiss<CR>', { desc = 'Dismiss Noice Message' })
