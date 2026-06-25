-- ============================================================================
-- STATUSLINE
-- ============================================================================
require("lualine").setup({
    options = {
        theme = 'catppuccin-mocha',
        component_separators = '',
        section_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
        lualine_b = { { 'filename', path = 1 }, 'filetype' },
        lualine_c = {},
        lualine_x = {},
        lualine_y = { 'branch', 'diff', 'diagnostics', 'progress' },
        lualine_z = {
            { 'location', separator = { right = '' }, left_padding = 2 },
        },
    },
    inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
    },
    tabline = {},
    extensions = {},
})
