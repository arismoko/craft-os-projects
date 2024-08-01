-- avim.lua

-- Key Mapping System
local avim = { keys = {} }
local KeyMap = {
    normal = {},
    insert = {},
    visual = {},
    command = {}
}

local keyStates = {
    shift = false,
    ctrl = false,
    alt = false
}

local modifierKeys = {
    [keys.leftShift] = "shift",
    [keys.rightShift] = "shift",
    [keys.leftCtrl] = "ctrl",
    [keys.rightCtrl] = "ctrl",
    [keys.leftAlt] = "alt",
    [keys.rightAlt] = "alt"
}

-- Function to parse key combinations
local function parseKeyCombo(combo)
    local modifiers = {}
    local mainKey

    for part in combo:gmatch("[^%s+]+") do
        if part == "ctrl" or part == "shift" or part == "alt" then
            table.insert(modifiers, part)
        else
            mainKey = part
        end
    end

    return modifiers, mainKey
end

-- Function to add key mappings
function avim.keys.map(mode, keyCombo, callback)
    local modifiers, mainKey = parseKeyCombo(keyCombo)
    local comboKey
    if #modifiers > 0 then
        comboKey = table.concat(modifiers, "+") .. (mainKey and "+" .. mainKey or "")
    else
        comboKey = mainKey
    end

    if not KeyMap[mode] then
        KeyMap[mode] = {}
    end

    KeyMap[mode][comboKey] = callback
    print("Mapped key:", comboKey, "to mode:", mode) -- Debugging statement
end

-- Function to handle key presses and releases
local function handleKeyPress(key, isDown, model, view)
    if modifierKeys[key] then
        -- Update the state of the modifier key (pressed or released)
        keyStates[modifierKeys[key]] = isDown
        print("Modifier key:", keys.getName(key), "is now", isDown and "down" or "up") -- Debugging statement
    else
        -- Create a combination key string
        local combo = {}
        if keyStates["ctrl"] then table.insert(combo, "ctrl") end
        if keyStates["shift"] then table.insert(combo, "shift") end
        if keyStates["alt"] then table.insert(combo, "alt") end
        table.insert(combo, keys.getName(key))
        local comboKey = table.concat(combo, "+")

        -- Trigger action based on the combo or single key press
        if isDown then
            if KeyMap[model.mode][comboKey] then
                print("Executing action for comboKey:", comboKey) -- Debugging statement
                KeyMap[model.mode][comboKey]()
            elseif KeyMap[model.mode][keys.getName(key)] then
                print("Executing action for single key:", keys.getName(key)) -- Debugging statement
                KeyMap[model.mode][keys.getName(key)]()
            else
                print("Unmapped key:", comboKey, "or", keys.getName(key), "in mode:", model.mode)  -- Debugging statement
            end
        end
    end
end

-- Function to handle key events
local function handleKeyEvent(mode, model, view)
    local event, key = os.pullEvent()

    if event == "key" then
        handleKeyPress(key, true, model, view)
    elseif event == "key_up" then
        handleKeyPress(key, false, model, view)
    end
end

-- Event loop to manage key press and release events
local function eventLoop(mode, model, view)
    while not model.shouldExit do
        local event, param1 = os.pullEvent()

        if event == "key" or event == "key_up" then
            handleKeyEvent(mode, model, view)
        elseif event == "char" then
            handleCharEvent(mode, param1, model, view)
        end

        -- Update the view if needed
        if model:updateScroll(view:getScreenHeight()) then
            view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        else
            view:drawLine(model, model.cursorY - model.scrollOffset)
        end
        view:updateCursor(model)
    end
end

-- Function to handle char events (only used in insert mode)
local function handleCharEvent(mode, char, model, view)
    if KeyMap[mode][char] then
        local mapping = KeyMap[mode][char]
        mapping.callback()
    else
        print("Unmapped char:", char, "in mode:", mode)  -- Debugging statement
    end
end

-- Command mapping table
local commands = {}

-- Function to add a new command
function commands.map(name, func)
    commands[name] = func
end

-- Command execution function
local function executeCommand(command, model, view)
    local args = {}
    for arg in command:gmatch("%S+") do
        table.insert(args, arg)
    end

    local commandName = args[1]
    table.remove(args, 1)  -- Remove the command name from the args

    if commands[commandName] then
        commands[commandName](model, view, unpack(args))
    else
        model.statusMessage = "Unknown command: " .. commandName
    end
end

-- Handle command input
local function handleCommandInput(model, view)
    local command = ""
    model.statusMessage = ":"  -- Start with a colon to indicate command mode
    view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())

    while true do
        local event, param1 = os.pullEvent()
        if event == "char" then
            command = command .. param1
            model.statusMessage = ":" .. command
            view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())
        elseif event == "key" then
            if param1 == keys.enter then
                executeCommand(command, model, view)
                return model.modes.handleNormalMode(model, view)  -- Return to normal mode after executing the command
            elseif param1 == keys.backspace then
                command = command:sub(1, -2)  -- Remove the last character
                model.statusMessage = ":" .. command
                view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())
            elseif param1 == keys.escape then
                return model.modes.handleNormalMode(model, view)  -- Exit command mode without executing
            end
        end
    end
end

-- Model
local Model = {
    buffer = {},
    cursorX = 1,
    cursorY = 1,
    scrollOffset = 0,
    filename = "",
    yankRegister = "",
    visualStartX = nil,
    visualStartY = nil,
    isVisualMode = false,
    history = {},
    redoStack = {},
    statusMessage = "",
    shouldExit = false,  -- New flag to signal when to exit
    modes = {}  -- Store mode-handling functions here
}

-- Function to save the current state to history
function Model:saveToHistory()
    table.insert(self.history, {
        buffer = table.deepCopy(self.buffer),
        cursorX = self.cursorX,
        cursorY = self.cursorY
    })
    self.redoStack = {}  -- Clear redo stack whenever a new action is performed
end

-- Helper function to deep copy a table (for history tracking)
function table.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepCopy(orig_key)] = table.deepCopy(orig_value)
        end
        setmetatable(copy, table.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Undo function
function Model:undo()
    if #self.history > 0 then
        local lastState = table.remove(self.history)
        table.insert(self.redoStack, {
            buffer = table.deepCopy(self.buffer),
            cursorX = self.cursorX,
            cursorY = self.cursorY
        })
        self.buffer = lastState.buffer
        self.cursorX = lastState.cursorX
        self.cursorY = lastState.cursorY
        self.statusMessage = "Undid last action"
    else
        self.statusMessage = "Nothing to undo"
    end
end

-- Redo function
function Model:redo()
    if #self.redoStack > 0 then
        local redoState = table.remove(self.redoStack)
        table.insert(self.history, {
            buffer = table.deepCopy(self.buffer),
            cursorX = self.cursorX,
            cursorY = self.cursorY
        })
        self.buffer = redoState.buffer
        self.cursorX = redoState.cursorX
        self.cursorY = redoState.cursorY
        self.statusMessage = "Redid last action"
    else
        self.statusMessage = "Nothing to redo"
    end
end

function Model:startVisualMode()
    self.visualStartX = self.cursorX
    self.visualStartY = self.cursorY
    self.isVisualMode = true
    self.statusMessage = "Entered visual mode"
end

function Model:endVisualMode()
    self.visualStartX = nil
    self.visualStartY = nil
    self.isVisualMode = false
    self.statusMessage = "Exited visual mode"
end

function Model:loadFile(name, view)
    self.filename = name
    self.buffer = {}
    if fs.exists(self.filename) then
        local file = fs.open(self.filename, "r")
        for line in file.readLine do
            table.insert(self.buffer, line)
        end
        file.close()
    else
        table.insert(self.buffer, "")
    end
    self.statusMessage = "Loaded file: " .. self.filename
    self.modes.handleNormalMode(self, view)
end

function Model:saveFile()
    local file = fs.open(self.filename, "w")
    for _, line in ipairs(self.buffer) do
        file.writeLine(line)
    end
    file.close()
    self.statusMessage = "File saved: " .. self.filename
end

function Model:updateScroll(screenHeight)
    local newScrollOffset = self.scrollOffset
    if self.cursorY < self.scrollOffset + 1 then
        newScrollOffset = self.cursorY - 1
    elseif self.cursorY > self.scrollOffset + screenHeight - 1 then
        newScrollOffset = self.cursorY - (screenHeight - 1)
    end

    if newScrollOffset ~= self.scrollOffset then
        self.scrollOffset = newScrollOffset
        return true
    end
    return false
end

function Model:insertChar(char)
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. char .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + 1
    self.statusMessage = "Inserted character"
end

function Model:backspace()
    if self.cursorX > 1 then
        self:saveToHistory()
        local line = self.buffer[self.cursorY]
        self.buffer[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
        self.cursorX = self.cursorX - 1
        self.statusMessage = "Deleted character"
    elseif self.cursorY > 1 then
        self:saveToHistory()
        local line = table.remove(self.buffer, self.cursorY)
        self.cursorY = self.cursorY - 1
        self.cursorX = #self.buffer[self.cursorY] + 1
        self.buffer[self.cursorY] = self.buffer[self.cursorY] .. line
        self.statusMessage = "Deleted line"
    end
end

function Model:enter()
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    local newLine = line:sub(self.cursorX)
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1)
    table.insert(self.buffer, self.cursorY + 1, newLine)
    self.cursorY = self.cursorY + 1
    self.cursorX = 1
    self.statusMessage = "Inserted new line"
end

function Model:yankLine()
    self.yankRegister = self.buffer[self.cursorY]
    self.statusMessage = "Yanked line"
end

function Model:paste()
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. self.yankRegister .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + #self.yankRegister
    self.statusMessage = "Pasted text"
end

function Model:yankSelection()
    local startX, startY = math.min(self.cursorX, self.visualStartX), math.min(self.cursorY, self.visualStartY)
    local endX, endY = math.max(self.cursorX, self.visualStartX), math.max(self.cursorY, self.visualStartY)

    self.yankRegister = ""  -- Clear yank register

    for y = startY, endY do
        local line = self.buffer[y]
        local yankText
        if y == startY and y == endY then
            yankText = line:sub(startX, endX - 1)
        elseif y == startY then
            yankText = line:sub(startX)
        elseif y == endY then
            yankText = line:sub(1, endX - 1)
        else
            yankText = line
        end
        self.yankRegister = self.yankRegister .. yankText .. "\n"
    end
    self.statusMessage = "Yanked selection"
end

function Model:cutSelection()
    self:saveToHistory()
    local startX, startY = math.min(self.cursorX, self.visualStartX), math.min(self.cursorY, self.visualStartY)
    local endX, endY = math.max(self.cursorX, self.visualStartX), math.max(self.cursorY, self.visualStartY)

    self.yankRegister = ""  -- Clear yank register

    for y = startY, endY do
        local line = self.buffer[y]
        local cutText
        if y == startY and y == endY then
            cutText = line:sub(startX, endX - 1)
            self.buffer[y] = line:sub(1, startX - 1) .. line:sub(endX)
        elseif y == startY then
            cutText = line:sub(startX)
            self.buffer[y] = line:sub(1, startX - 1)
        elseif y == endY then
            cutText = line:sub(1, endX - 1)
            self.buffer[y] = line:sub(endX)
        else
            cutText = line
            self.buffer[y] = ""
        end
        self.yankRegister = self.yankRegister .. cutText .. "\n"
    end

    -- Move cursor to the start of the selection
    self.cursorX = startX
    self.cursorY = startY

    -- Handle merging lines if needed
    if startY ~= endY then
        self.buffer[startY] = self.buffer[startY] .. self.buffer[startY + 1]
        table.remove(self.buffer, startY + 1)
    end

    self.statusMessage = "Cut selection"
end

function Model:cutLine()
    self:saveToHistory()
    self.yankRegister = self.buffer[self.cursorY]  -- Store the current line in yankRegister
    table.remove(self.buffer, self.cursorY)        -- Remove the line from the buffer
    if self.cursorY > #self.buffer then
        self.cursorY = #self.buffer  -- Adjust cursor position if needed
    end
    self.cursorX = 1
    self.statusMessage = "Cut line"
end

-- View
local View = {
    screenWidth = 0,
    screenHeight = 0
}

function View:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function View:getScreenWidth()
    return self.screenWidth
end

function View:getScreenHeight()
    return self.screenHeight
end

function View:drawScreen(model, screenWidth, screenHeight)
    term.clear()
    for i = 1, screenHeight - 1 do
        self:drawLine(model, i)
    end
    self:drawStatusBar(model, screenWidth, screenHeight)
    term.setCursorPos(model.cursorX, model.cursorY - model.scrollOffset)
    term.setCursorBlink(true)
end

function View:drawLine(model, y)
    local lineIndex = model.scrollOffset + y
    term.setCursorPos(1, y)
    term.clearLine()

    if model.buffer[lineIndex] then
        if model.isVisualMode and model.visualStartY and lineIndex >= math.min(model.visualStartY, model.cursorY) and lineIndex <= math.max(model.visualStartY, model.cursorY) then
            -- Highlight the text in the visual selection range
            local startX = 1
            local endX = #model.buffer[lineIndex]
            if lineIndex == model.visualStartY then startX = model.visualStartX end
            if lineIndex == model.cursorY then endX = model.cursorX end

            local beforeHighlight = model.buffer[lineIndex]:sub(1, startX - 1)
            local highlightText = model.buffer[lineIndex]:sub(startX, endX)
            local afterHighlight = model.buffer[lineIndex]:sub(endX + 1)

            term.write(beforeHighlight)
            term.setBackgroundColor(colors.gray)
            term.write(highlightText)
            term.setBackgroundColor(colors.black)
            term.write(afterHighlight)
        else
            term.write(model.buffer[lineIndex])
        end
    end
end

function View:drawStatusBar(model, screenWidth, screenHeight)
    term.setCursorPos(1, screenHeight)
    term.setBackgroundColor(colors.green)
    term.clearLine()
    term.setTextColor(colors.white)
    term.write("File: " .. model.filename .. " | Pos: " .. model.cursorY .. "," .. model.cursorX)

    if model.statusMessage ~= "" then
        term.setCursorPos(screenWidth - #model.statusMessage - 1, screenHeight)
        term.write(model.statusMessage)
    end

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function View:updateCursor(model)
    term.setCursorPos(model.cursorX, model.cursorY - model.scrollOffset)
end

-- Mode Handlers
local function handleNormalMode(model, view)
    view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
    print("Entered Normal Mode")  -- Debugging statement
    
    -- Event loop to keep handling events until the program should exit
    while not model.shouldExit do
        -- Only pull for "key" events
        local event, param1 = os.pullEvent("key")
        
        -- Handle the key event
        handleKeyEvent("normal", model, view)

        -- Update the view based on cursor and scroll changes
        if model:updateScroll(view:getScreenHeight()) then
            view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        else
            view:drawLine(model, model.cursorY - model.scrollOffset)
        end
        view:updateCursor(model)
    end
end

local function handleInsertMode(model, view)
    term.setCursorBlink(true)
    model.statusMessage = "Insert mode"
    view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())
    print("Entered Insert Mode")  -- Debugging statement

    while true do
        local event, param1 = os.pullEvent()
        if event == "char" then
            model:insertChar(param1)
            view:drawLine(model, model.cursorY - model.scrollOffset)
        elseif event == "key" then
            handleKeyEvent("insert", model, view)
            if param1 == keys.backspace then
                model:backspace()
                view:drawLine(model, model.cursorY - model.scrollOffset)
                view:updateCursor(model)
            elseif param1 == keys.enter then
                model:enter()
                model:updateScroll(view:getScreenHeight())
                view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
            elseif param1 == keys.f1 then  -- Correctly transition back to normal mode
                model.statusMessage = "Exited insert mode"
                return handleNormalMode(model, view)
            end
        end
        view:updateCursor(model)
    end
end

local function handleVisualMode(model, view)
    view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
    print("Entered Visual Mode")  -- Debugging statement
    while true do
        local event, param1 = os.pullEvent("key")
        handleKeyEvent("visual", model, view)

        if param1 == keys.v then
            model:endVisualMode()
            return handleNormalMode(model, view)
        elseif param1 == keys.y then
            -- Yank selected text
            model:yankSelection()
            model:endVisualMode()
            return handleNormalMode(model, view)
        elseif param1 == keys.d then
            -- Cut selected text
            model:cutSelection()
            view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
            return handleNormalMode(model, view)
        elseif param1 == keys.escape then
            model:endVisualMode()
            return handleNormalMode(model, view)
        end

        if model:updateScroll(view:getScreenHeight()) then
            view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        else
            view:drawLine(model, model.cursorY - model.scrollOffset)
        end
        view:updateCursor(model)
    end
end

-- Main Program
local screenWidth, screenHeight = term.getSize()
View:setScreenSize(screenWidth, screenHeight)

-- Load keybindings
local setupKeybinds = require("keybinds")
setupKeybinds(avim, Model, View, {
    handleNormalMode = handleNormalMode,
    handleInsertMode = handleInsertMode,
    handleVisualMode = handleVisualMode
})

-- Load commands
local setupCommands = require("commands")
setupCommands(commands, Model, View)

-- Store mode handlers in the Model for easy access
Model.modes.handleNormalMode = handleNormalMode
Model.modes.handleInsertMode = handleInsertMode
Model.modes.handleVisualMode = handleVisualMode

local function LaunchScreen()
    term.clear()
    term.setCursorPos(1, 1)
    print("Welcome to AVIM")
    print("Press 'n' to create a new file")
    print("Press 'o' to open a file")
    print("Press 'q' to quit")
    while not Model.shouldExit do  -- Check the exit flag here
        local event, param1 = os.pullEvent("key")
        if param1 == keys.n then
            term.clear()
            term.setCursorPos(1, 1)
            print("Enter filename:")
            Model.filename = read()
            Model:loadFile(Model.filename, View)
        elseif param1 == keys.o then
            term.clear()
            term.setCursorPos(1, 1)
            print("Enter filename:")
            Model.filename = read()
            Model:loadFile(Model.filename, View)
        elseif param1 == keys.q then
            Model.shouldExit = true  -- Set the exit flag
        end
    end
end
-- Launch the screen
LaunchScreen()

-- Expose everything for external usage
return {
    avim = avim,
    Model = Model,
    View = View,
    handleNormalMode = handleNormalMode,
    handleInsertMode = handleInsertMode,
    handleVisualMode = handleVisualMode,
    handleCommandMode = handleCommandInput  -- Expose the new command mode
}
