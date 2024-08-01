-- avim.lua

-- Key Mapping System
local avim = { keys = {} }
local KeyMap = {
    normal = {},
    insert = {},
    visual = {}  -- Visual mode
}

-- Function to parse key combinations
local function parseKeyCombo(combo)
    local modifiers = {}
    local mainKey

    for part in combo:gmatch("[^%s+]+") do
        if part == "ctrl" or part == "shift" or part == "alt" then
            table.insert(modifiers, part)
        elseif part == "c^" then
            table.insert(modifiers, "ctrl")
        elseif part == "a^" then
            table.insert(modifiers, "alt")
        else
            mainKey = part
        end
    end

    return modifiers, mainKey
end

-- Function to add key mappings
function avim.keys.map(mode, keyCombo, callback)
    local modifiers, mainKey = parseKeyCombo(keyCombo)
    KeyMap[mode][mainKey] = {callback = callback, modifiers = modifiers}
end

-- Function to check if a modifier key is pressed
local function isModifierPressed(modifier)
    if modifier == "ctrl" then
        return keys.leftCtrl or keys.rightCtrl
    elseif modifier == "alt" then
        return keys.leftAlt or keys.rightAlt
    else
        return false
    end
end

-- Function to handle key events based on mode
local function handleKeyEvent(mode, param1, model, view)
    local keyCombo = keys.getName(param1)  -- Get the main key name

    if KeyMap[mode][keyCombo] then
        local mapping = KeyMap[mode][keyCombo]
        local allModifiersPressed = true

        for _, modifier in ipairs(mapping.modifiers) do
            if not isModifierPressed(modifier) then
                allModifiersPressed = false
                break
            end
        end

        if allModifiersPressed then
            mapping.callback()
        end

        -- Update status line for Ctrl or Alt presses
        if isModifierPressed("ctrl") then
            model.statusMessage = "Ctrl pressed!"
        elseif isModifierPressed("alt") then
            model.statusMessage = "Alt pressed!"
        end
        view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())
    else
        print("Unmapped key:", keyCombo, "in mode:", mode)  -- Debugging statement
    end
end

-- Function to handle char events (for checking uppercase and lowercase distinctions)
local function handleCharEvent(mode, char, model, view)
    if KeyMap[mode][char] then
        local mapping = KeyMap[mode][char]
        mapping.callback()
    else
        print("Unmapped char:", char, "in mode:", mode)  -- Debugging statement
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

function Model:loadFile(name)
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
    -- Transition to Normal mode after loading the file
    self.modes.handleNormalMode(self, View)
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

-- New function to handle yanking the highlighted text in visual mode
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

-- New function to handle cutting the highlighted text in visual mode
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

-- Function to cut the current line in normal mode
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
    while not model.shouldExit do  -- Check the exit flag here
        local event, param1 = os.pullEvent()
        if event == "key" then
            handleKeyEvent("normal", param1, model, view)
        elseif event == "char" then
            handleCharEvent("normal", param1, model, view)
        end

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
            handleKeyEvent("insert", param1, model, view)
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
        handleKeyEvent("visual", param1, model, view)

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
            Model:loadFile(Model.filename)
        elseif param1 == keys.o then
            term.clear()
            term.setCursorPos(1, 1)
            print("Enter filename:")
            Model.filename = read()
            Model:loadFile(Model.filename)
        elseif param1 == keys.q then
            Model.shouldExit = true  -- Set the exit flag
        end
    end
end

LaunchScreen()

-- Expose everything for external usage
return {
    avim = avim,
    Model = Model,
    View = View,
    handleNormalMode = handleNormalMode,
    handleInsertMode = handleInsertMode,
    handleVisualMode = handleVisualMode
}