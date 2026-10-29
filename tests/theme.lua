-- Run from the repository root:
-- nvim --clean -n --headless -i NONE -l tests/theme.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local function highlight(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function luminance(color)
    local channels = { math.floor(color / 65536), math.floor(color / 256) % 256, color % 256 }
    for index, channel in ipairs(channels) do
        channel = channel / 255
        channels[index] = channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
    end
    return 0.2126 * channels[1] + 0.7152 * channels[2] + 0.0722 * channels[3]
end

local function contrast(fg, bg)
    local first, second = luminance(fg), luminance(bg)
    return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05)
end

vim.o.background = "light"
vim.cmd("syntax off")
vim.cmd("colorscheme minimalx")
assert(vim.o.background == "dark", "The theme must select a dark background")
assert(vim.g.colors_name == "minimalx", "The theme must register its name")
assert(vim.o.termguicolors, "True color must be enabled")
assert(vim.fn.exists("syntax_on") == 0, "Loading a theme must not enable disabled syntax")

local normal = highlight("Normal")
for _, name in ipairs({ "Normal", "Comment", "LineNr", "String", "Function", "Keyword", "Type", "Number" }) do
    assert(contrast(highlight(name).fg, normal.bg) >= 4.5, name .. " must remain readable")
end
for _, name in ipairs({ "Visual", "PmenuSel", "LspReferenceText", "LspReferenceWrite" }) do
    local group = highlight(name)
    assert(group.bg ~= normal.bg, name .. " must be visible")
    assert(contrast(group.fg or normal.fg, group.bg) >= 4.5, name .. " must preserve text contrast")
end
assert(highlight("PmenuSel").bg ~= highlight("Pmenu").bg, "Completion selection must stand out")
assert(highlight("CursorLineNr").fg ~= highlight("LineNr").fg, "The current line must stand out")

local seen = {}
for _, severity in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    local color = highlight("Diagnostic" .. severity).fg
    assert(not seen[color], "Diagnostic severities must have distinct colors")
    assert(contrast(color, normal.bg) >= 4.5, "Diagnostic text must remain readable")
    assert(highlight("DiagnosticUnderline" .. severity).sp == color, "Diagnostic underlines must match")
    seen[color] = true
end
seen = {}
for _, name in ipairs({ "DiffAdd", "DiffChange", "DiffDelete", "DiffText" }) do
    local background = highlight(name).bg
    assert(not seen[background], "Diff states must have distinct backgrounds")
    seen[background] = true
end
seen = {}
for index = 0, 15 do
    local color = vim.g["terminal_color_" .. index]
    assert(color:match("^#%x%x%x%x%x%x$"), "Every ANSI color must be defined")
    assert(not seen[color], "Every ANSI color must be distinct, including bright variants")
    seen[color] = true
end

-- Exercise syntax in an actual buffer, rather than only inspecting definitions.
vim.cmd("syntax enable")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '-- a comment', 'local message = "hello"', 'return 42' })
vim.bo.filetype = "lua"
vim.treesitter.stop(0)
vim.bo.syntax = "lua"
local function syntax_color(line, column)
    local id = vim.fn.synIDtrans(vim.fn.synID(line, column, 1))
    return vim.fn.synIDattr(id, "fg#", "gui")
end
assert(syntax_color(1, 1) ~= syntax_color(2, 18), "Comments and strings must differ in a real buffer")
assert(syntax_color(2, 18) ~= syntax_color(3, 8), "Strings and numbers must differ in a real buffer")

for _, pair in ipairs({
    { "@boolean", "Boolean" }, { "@number.float", "Float" }, { "@function.method.call", "Function" },
    { "@lsp.type.enumMember", "Constant" }, { "@lsp.type.parameter", "Identifier" },
    { "TelescopeSelection", "PmenuSel" }, { "BlinkCmpMenuSelection", "PmenuSel" },
    { "GitSignsAdd", "Added" }, { "NeogitDiffDelete", "DiffDelete" },
}) do
    assert(vim.deep_equal(highlight(pair[1]), highlight(pair[2])), pair[1] .. " must follow its base group")
end

vim.cmd("colorscheme default")
vim.cmd("colorscheme minimalx")
assert(vim.deep_equal(highlight("Normal"), normal), "Switching themes must restore the palette")
assert(vim.v.errmsg == "", vim.v.errmsg)
print("MinimalX: startup, contrast, syntax, diagnostics, terminal colors, plugin links, and reload passed")
