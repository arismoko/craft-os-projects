-- keybinds.lua
local KeyHandler = require("KeyHandler"):getInstance()
local Model = require("Model"):getInstance()
local View = require("View"):getInstance()

-- === Normal Mode Keybindings ===

-- Basic Navigation
KeyHandler:map("normal", "h", function()
    Model.cursorX = math.max(1, Model.cursorX - 1)
end)

KeyHandler:map("normal", "j", function()
    if Model.cursorY < #Model.buffer then
        Model.cursorY = Model.cursorY + 1
    end
    Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
end)

KeyHandler:map("normal", "k", function()
    if Model.cursorY > 1 then
        Model.cursorY = Model.cursorY - 1
    end
    Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
end)

KeyHandler:map("normal", "l", function()
    Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
end)

-- Word and Line Motions
KeyHandler:map("normal", "w", function()
    local line = Model.buffer[Model.cursorY]
    local nextSpace = line:find("%s", Model.cursorX)
    if nextSpace then
        Model.cursorX = nextSpace + 1
    else
        Model.cursorX = #line + 1
    end
end)

KeyHandler:map("normal", "shift + w", function()
    local line = Model.buffer[Model.cursorY]
    local nextSpace = line:find("%s", Model.cursorX)
    if nextSpace then
        local nextWordStart = line:find("%S", nextSpace + 1)
        if nextWordStart then
            Model.cursorX = nextWordStart
        else
            Model.cursorX = #line + 1
        end
    else
        Model.cursorX = #line + 1
    end
end)

KeyHandler:map("normal", "b", function()
    local line = Model.buffer[Model.cursorY]
    local prevSpace = line:sub(1, Model.cursorX - 1):find("%s[^%s]*$")
    if prevSpace then
        Model.cursorX = prevSpace
    else
        Model.cursorX = 1
    end
end)

KeyHandler:map("normal", "shift + b", function()
    local line = Model.buffer[Model.cursorY]
    local prevWordEnd = line:sub(1, Model.cursorX - 1):find("%S[%s]*$")
    if prevWordEnd then
        local prevWordStart = line:sub(1, prevWordEnd):find("%s*[^%s]*$")
        Model.cursorX = prevWordStart
    else
        Model.cursorX = 1
    end
end)

KeyHandler:map("normal", "e", function()
    local line = Model.buffer[Model.cursorY]
    local nextWordEnd = line:find("[^%s]+", Model.cursorX)
    if nextWordEnd then
        Model.cursorX = nextWordEnd + line:sub(nextWordEnd):find("%s") - 1
    else
        Model.cursorX = #line + 1
    end
end)

KeyHandler:map("normal", "shift + e", function()
    local line = Model.buffer[Model.cursorY]
    local nextWordEnd = line:find("%S[%s]*", Model.cursorX)
    if nextWordEnd then
        Model.cursorX = nextWordEnd
    else
        Model.cursorX = #line + 1
    end
end)

KeyHandler:map("normal", "0", function()
    Model.cursorX = 1
end)

KeyHandler:map("normal", "shift + 4", function()
    Model.cursorX = #Model.buffer[Model.cursorY] + 1
end)

KeyHandler:map("normal", "shift + 6", function()
    local line = Model.buffer[Model.cursorY]
    local firstNonBlank = line:find("%S")
    if firstNonBlank then
        Model.cursorX = firstNonBlank
    else
        Model.cursorX = 1
    end
end)

-- File and Screen Navigation
KeyHandler:map("normal", "g", function()
    local pressedG = false
    return function(key)
        if key == keys.g then
            if pressedG then
                Model.cursorY = 1
                Model.cursorX = 1
                pressedG = false
                View:drawScreen()
                Model:updateStatusBar("Moved to top of file")
            else
                pressedG = true
            end
        else
            pressedG = false
        end
    end
end)

KeyHandler:map("normal", "shift + g", function()
    Model.cursorY = #Model.buffer
    Model.cursorX = 1
end)

KeyHandler:map("normal", "shift + h", function()
    local screenStart = Model.scrollOffset + 1
    Model.cursorY = screenStart
    Model.cursorX = 1
    View:drawScreen()
    Model:updateStatusBar("Moved to top of screen")
end)

KeyHandler:map("normal", "shift + m", function()
    local screenHeight = View:getScreenHeight()
    local screenMiddle = math.floor(screenHeight / 2)
    Model.cursorY = Model.scrollOffset + screenMiddle
    Model.cursorX = 1
    View:drawScreen()
    Model:updateStatusBar("Moved to middle of screen")
end)

KeyHandler:map("normal", "shift + l", function()
    local screenHeight = View:getScreenHeight()
    local screenEnd = Model.scrollOffset + screenHeight - 1
    Model.cursorY = screenEnd
    Model.cursorX = 1
    View:drawScreen()
    Model:updateStatusBar("Moved to bottom of screen")
end)

-- Editing
KeyHandler:map("normal", "x", function()
    local line = Model.buffer[Model.cursorY]
    if Model.cursorX <= #line then
        Model.buffer[Model.cursorY] = line:sub(1, Model.cursorX - 1) .. line:sub(Model.cursorX + 1)
        View:drawLine(Model.cursorY - Model.scrollOffset)
        Model:updateStatusBar("Deleted character")
    else
        Model:updateStatusError("Nothing to delete")
    end
end)

KeyHandler:map("normal", "shift + x", function()
    local line = Model.buffer[Model.cursorY]
    if Model.cursorX > 1 then
        Model.buffer[Model.cursorY] = line:sub(1, Model.cursorX - 2) .. line:sub(Model.cursorX)
        Model.cursorX = Model.cursorX - 1
        View:drawLine(Model.cursorY - Model.scrollOffset)
        Model:updateStatusBar("Deleted character")
    else
        Model:updateStatusError("Nothing to delete")
    end
end)

KeyHandler:map("normal", "d", function()
    Model:cutLine()
    View:drawScreen()
end)

KeyHandler:map("normal", "d + w", function()
    local line = Model.buffer[Model.cursorY]
    local nextSpace = line:find("%s", Model.cursorX)
    if nextSpace then
        line = line:sub(1, Model.cursorX - 1) .. line:sub(nextSpace + 1)
    else
        line = line:sub(1, Model.cursorX - 1)
    end
    Model.buffer[Model.cursorY] = line
    Model:updateStatusBar("Deleted word")
    View:drawScreen()
end)

KeyHandler:map("normal", "c + w", function()
    local line = Model.buffer[Model.cursorY]
    local nextSpace = line:find("%s", Model.cursorX)
    if nextSpace then
        line = line:sub(1, Model.cursorX - 1) .. line:sub(nextSpace + 1)
    else
        line = line:sub(1, Model.cursorX - 1)
    end
    Model.buffer[Model.cursorY] = line
    Model:switchMode("insert")
    View:drawScreen()
end)

KeyHandler:map("normal", "y", function()
    Model:yankLine()
end)

KeyHandler:map("normal", "p", function()
    Model:paste()
    View:drawLine(Model.cursorY - Model.scrollOffset)
    Model:updateStatusBar("Pasted text")
end)

KeyHandler:map("normal", "u", function()
    Model:undo()
    View:drawScreen()
end)

KeyHandler:map("normal", "ctrl + u", function()
    Model:redo()
    View:drawScreen()
end)

-- Mode Switching
KeyHandler:map("normal", "i", function()
    Model:switchMode("insert")
end)

KeyHandler:map("normal", "a", function()
    Model.cursorX = math.min(Model.cursorX + 1, #Model.buffer[Model.cursorY] + 1)
    Model:switchMode("insert")
end)

KeyHandler:map("normal", "shift + a", function()
    Model.cursorX = #Model.buffer[Model.cursorY] + 1
    Model:switchMode("insert")
end)

KeyHandler:map("normal", "shift + i", function()
    local line = Model.buffer[Model.cursorY]
    local firstNonBlank = line:find("%S")
    if firstNonBlank then
        Model.cursorX = firstNonBlank
    else
        Model.cursorX = 1
    end
    Model:switchMode("insert")
end)

KeyHandler:map("normal", "o", function()
    local line = Model.cursorY
    table.insert(Model.buffer, line + 1, "")
    Model.cursorY = line + 1
    Model.cursorX = 1
    Model:switchMode("insert")
    View:drawScreen()
end)

KeyHandler:map("normal", "shift + o", function()
    local line = Model.cursorY
    table.insert(Model.buffer, line, "")
    Model.cursorY = line
    Model.cursorX = 1
    Model:switchMode("insert")
    View:drawScreen()
end)

KeyHandler:map("normal", "shift + semicolon", function()
    Model:switchMode("command")
end)

KeyHandler:map("normal", "v", function()
    Model:startVisualMode()
end)

KeyHandler:map("normal", "f9", function()
    Model.shouldExit = true
end)

-- Miscellaneous
KeyHandler:map("normal", "f1", function()
    local keybindsWindow = View:createWindow(1, 1)
    keybindsWindow:print("Current Keybindings:")
    for mode, keyMap in pairs(KeyHandler.keyMap) do
        keybindsWindow:writeline(" ")
        keybindsWindow:writeline("Mode: " .. mode)
        local i = 1
        for key, _ in pairs(keyMap) do
            keybindsWindow:write("  " .. i .. ": " .. key .. ",")
            i = i + 1
        end
    end
    keybindsWindow:show()
end)

KeyHandler:map("normal", "f4", function()
    View:closeAllWindows()
end)

-- === Visual Mode Keybindings ===

-- Basic Navigation
KeyHandler:map("visual", "h", function()
    Model.cursorX = math.max(1, Model.cursorX - 1)
    View:drawScreen()
end)

KeyHandler:map("visual", "j", function()
    if Model.cursorY < #Model.buffer then
        Model.cursorY = Model.cursorY + 1
    end
    Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    View:drawScreen()
end)

KeyHandler:map("visual", "k", function()
    if Model.cursorY > 1 then
        Model.cursorY = Model.cursorY - 1
    end
    Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    View:drawScreen()
end)

KeyHandler:map("visual", "l", function()
    Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
    View:drawScreen()
end)

-- Editing
KeyHandler:map("visual", "y", function()
    Model:yankSelection()
    Model:endVisualMode()
end)

KeyHandler:map("visual", "d", function()
    Model:cutSelection()
    View:drawScreen()
end)

-- Mode Switching
KeyHandler:map("visual", "escape", function()
    Model:endVisualMode()
end)

-- === Insert Mode Keybindings ===

-- Mode Switching
KeyHandler:map("insert", "escape", function()
    Model:switchMode("normal")
end)
