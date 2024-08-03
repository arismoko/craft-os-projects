-- example.lua
local lexer = dofile("lexer/lexer.lua") -- Load the lexer library
local lua_lexer = dofile("lexer/media/lexers/lua.lua") -- Load the Lua lexer

-- Sample Lua code to highlight
local code = [[
-- This is a comment
local x = 42
print("Hello, World!")
]]

-- Function to get tokens and apply styles
function highlight_code(code)
    local tokens = {}
    for token, text in lua_lexer:lex(code) do
        table.insert(tokens, {token = token, text = text})
    end
    return tokens
end

-- Function to draw the highlighted code in CraftOS
function draw_highlighted_code(tokens)
    term.clear()
    term.setCursorPos(1, 1)
    for _, part in ipairs(tokens) do
        local color = get_color_for_token(part.token)
        term.setTextColor(color)
        term.write(part.text)
    end
    term.setTextColor(colors.white)  -- Reset to default
end

-- Map tokens to colors
function get_color_for_token(token)
    local token_colors = {
        keyword = colors.blue,
        string = colors.orange,
        comment = colors.gray,
        number = colors.yellow,
        identifier = colors.white,
        operator = colors.lightGray,
        -- Add more mappings as needed
    }
    return token_colors[token] or colors.white
end

-- Run the example
local tokens = highlight_code(code)
draw_highlighted_code(tokens)
