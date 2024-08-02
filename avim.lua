-- main.lua
local Model = require("Model")
local View = require("View")
local KeyHandler = require("KeyHandler")
local CommandHandler = require("CommandHandler")

local screenWidth, screenHeight = term.getSize()

-- Instantiate classes
local model = Model:new()
local view = View:new(screenWidth, screenHeight)
local keyHandler = KeyHandler:new()
local commandHandler = CommandHandler:new()

-- Load keybindings and commands (these would be in separate files)
local setupKeybinds = require("keybinds")
setupKeybinds(keyHandler, model, view)

local setupCommands = require("commands")
setupCommands(commandHandler, model, view)

-- Main event loop
local function eventLoop()
    while not model.shouldExit do
        keyHandler:handleKeyEvent(model.mode, model, view)

        if model:updateScroll(view:getScreenHeight()) then
            view:drawScreen(model)
        else
            view:drawLine(model, model.cursorY - model.scrollOffset)
        end
        view:updateCursor(model)
    end
end

-- Launch the main program
term.clear()
term.setCursorPos(1, 1)
print("Welcome to AVIM")
print("Press 'n' to create a new file")
print("Press 'o' to open a file")
print("Press 'q' to quit")

while not model.shouldExit do
    local event, key = os.pullEvent("key")
    if key == keys.n then
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter filename:")
        model.filename = read()
        model:loadFile(model.filename)
        eventLoop()
    elseif key == keys.o then
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter filename:")
        model.filename = read()
        model:loadFile(model.filename)
        eventLoop()
    elseif key == keys.q then
        model.shouldExit = true
    end
end
