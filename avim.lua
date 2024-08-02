-- main.lua
local View = require("View"):getInstance()
local Model = require("Model"):getInstance()
local KeyHandler = require("KeyHandler"):getInstance()
local CommandHandler = require("CommandHandler"):getInstance()

local screenWidth, screenHeight = term.getSize()

-- Initialize the View singleton with screen dimensions
View:new(screenWidth, screenHeight)

-- Load keybindings

-- Main event loop
local function eventLoop()
    while not Model.shouldExit do
        KeyHandler:handleKeyEvent(Model.mode, Model, View, CommandHandler)

        if Model:updateScroll(View:getScreenHeight()) then
            View:drawScreen(Model)
        else
            View:drawLine(Model.cursorY - Model.scrollOffset)
        end
        View:updateCursor(Model)
    end
end

-- Launch the main program
term.clear()
term.setCursorPos(1, 1)
print("Welcome to AVIM")
print("Press 'n' to create a new file")
print("Press 'o' to open a file")
print("Press 'q' to quit")

while not Model.shouldExit do
    local event, key = os.pullEvent("key")
    if key == keys.n then
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter filename:")
        Model.filename = read()
        Model:loadFile(Model.filename)
        eventLoop()
    elseif key == keys.o then
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter filename:")
        Model.filename = read()
        Model:loadFile(Model.filename)
        eventLoop()
    elseif key == keys.q then
        Model.shouldExit = true
    end
end
