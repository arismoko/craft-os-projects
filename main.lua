local View = require("View"):getInstance()
local Model = require("Model"):getInstance()
local KeyHandler = require("KeyHandler"):getInstance()
local CommandHandler = require("CommandHandler"):getInstance()
local screenWidth, screenHeight = term.getSize()

-- Initialize the View singleton with screen dimensions
View:new(screenWidth, screenHeight)

-- Load keybindings
require("keybinds")
-- Load commands
require("commands")

local function handleFileOperation(prompt)
    term.clear()
    term.setCursorPos(1, 1)
    print(prompt)
    
    local firstInput = true
    local filename = ""
    while true do
        local event, param1 = os.pullEvent()
        if event == "char" then
            if firstInput then
                firstInput = false  -- Discard the first input
            else
                filename = filename .. param1  -- Append the rest of the input
                term.write(param1)  -- Display the input
            end
        elseif event == "key" then
            if param1 == keys.enter then
                return filename  -- Return the filename when Enter is pressed
            elseif param1 == keys.backspace then
                if #filename > 0 then
                    filename = filename:sub(1, -2)  -- Handle backspace
                    -- Get current cursor position
                    local cx, cy = term.getCursorPos()
                    -- Move cursor back one position and clear the character
                    term.setCursorPos(cx - 1, cy)
                    term.write(" ")
                    -- Move cursor back again to correct position
                    term.setCursorPos(cx - 1, cy)
                end
            end
        end
    end
end



-- Main event loop
local function eventLoop()
    View:drawScreen()
    while not Model.shouldExit do
        KeyHandler:handleInputEvent(Model.mode, Model, View, CommandHandler)
        View:updateCursor()
    end
    term.clear()
    term.setCursorPos(1, 1)
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
        local filename = handleFileOperation("Enter filename:")
        if filename and filename ~= "" then
            Model.filename = filename
            Model:loadFile(Model.filename)
            eventLoop()
        end
    elseif key == keys.o then
        local filename = handleFileOperation("Enter filename:")
        if filename and filename ~= "" then
            Model.filename = filename
            Model:loadFile(Model.filename)
            eventLoop()
        end
    elseif key == keys.q then
        Model.shouldExit = true
    end
end
