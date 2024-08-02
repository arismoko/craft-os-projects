-- keybinds.lua
local KeyHandler = require("KeyHandler"):getInstance()
local Model = require("Model"):getInstance()
local View = require("View"):getInstance()

-- Normal mode keybindings
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

KeyHandler:map("normal", "y", function()
    Model:yankLine()
end)

KeyHandler:map("normal", "p", function()
    Model:paste()
    View:drawLine(Model.cursorY - Model.scrollOffset)
    Model:updateStatusBar("Pasted text")
end)

KeyHandler:map("normal", "d", function()
    Model:cutLine()
    View:drawScreen()
end)

KeyHandler:map("normal", "u", function()
    Model:undo()
    View:drawScreen()
end)

KeyHandler:map("normal", "ctrl + r", function()
    Model:redo()
    View:drawScreen()
end)

KeyHandler:map("normal", "shift + ;", function()
    Model:switchMode("command")
end)
KeyHandler:map("normal", "i", function ()
    Model:switchMode("insert")
end)
    
KeyHandler:map("normal", "v", function()
    Model:startVisualMode()
end)
KeyHandler:map("normal", "f9", function()
    Model.shouldExit = true
end)

-- Visual mode keybindings
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

KeyHandler:map("visual", "y", function()
    Model:yankSelection()
    Model:endVisualMode()
end)

KeyHandler:map("visual", "d", function()
    Model:cutSelection()
    View:drawScreen()
end)

KeyHandler:map("visual", "escape", "switch:normal")

-- Insert mode keybindings
KeyHandler:map("insert", "escape", "switch:normal")

KeyHandler:map("normal", "f1", function()
    -- Create a new window that uses the maximum available size
    local keybindsWindow = View:createWindow(1, 1)

    -- Print some text in the window
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

    -- Show the window
    keybindsWindow:show()
end)

KeyHandler:map("normal", "f4", function()
    View:closeAllWindows()
end)


