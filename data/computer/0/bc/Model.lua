-- Model.lua
Model = {}
Model.__index = Model

local instance
local cachedView -- This will hold the cached View instance

function Model:new()
    if not instance then
        instance = {
            buffer = {},
            cursorX = 1,
            cursorY = 1,
            scrollOffset = 0,
            filename = "",
            yankRegister = "",
            visualStartX = nil,
            visualStartY = nil,
            isVisualMode = false,
            InputMode = "keys", -- Used to decide whether to handle key events or char events: keys or chars
            history = {},
            redoStack = {},
            statusMessage = "",
            shouldExit = false,
            mode = "normal",
            statusColor = colors.green, -- Default status bar color
            statusBarHeight = 2 -- Height of the status bar (dynamically tracked)
        }
        setmetatable(instance, Model)
    end
    return instance
end

function Model:getInstance()
    if not instance then
        instance = Model:new()
    end
    return instance
end

-- Lazy loading and caching of the View instance
local function getView()
    if not cachedView then
        cachedView = require("View"):getInstance()
    end
    return cachedView
end

function Model:updateStatusBar(message)
    local view = getView() -- Get the cached or lazily loaded View instance
    self.statusMessage = message
    self.statusColor = colors.green -- Reset to default color
    view:drawStatusBar(view:getScreenWidth(), view:getScreenHeight())
end

function Model:updateStatusError(message)
    local view = getView() -- Get the cached or lazily loaded View instance
    self.statusMessage = message
    self.statusColor = colors.red -- Set color to red for errors
    view:drawStatusBar(view:getScreenWidth(), view:getScreenHeight())
end

function Model:clearStatusBar()
    local view = getView() -- Get the cached or lazily loaded View instance
    self.statusMessage = ""
    self.statusColor = colors.green -- Reset to default color
    view:drawStatusBar(view:getScreenWidth(), view:getScreenHeight())
end

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
        self:updateStatusBar("Undid last action")
    else
        self:updateStatusError("Nothing to undo")
    end
end

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
        self:updateStatusBar("Redid last action")
    else
        self:updateStatusError("Nothing to redo")
    end
end

function Model:startVisualMode()
    self.visualStartX = self.cursorX
    self.visualStartY = self.cursorY
    self.isVisualMode = true
    self:updateStatusBar("Entered visual mode")
    self:switchMode("visual") -- Switch to visual mode
end

function Model:endVisualMode()
    self.visualStartX = nil
    self.visualStartY = nil
    self.isVisualMode = false
    self:updateStatusBar("Exited visual mode")
    self:switchMode("normal") -- Switch back to normal mode
    
    -- Redraw the screen to remove highlights
    local view = getView()
    view:drawScreen()
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
        self:updateStatusBar("Loaded file: " .. self.filename)
    else
        table.insert(self.buffer, "")
        self:updateStatusError("File not found, created new file: " .. self.filename)
    end
end

function Model:saveFile()
    local file = fs.open(self.filename, "w")
    for _, line in ipairs(self.buffer) do
        file.writeLine(line)
    end
    file.close()
    self:updateStatusBar("File saved: " .. self.filename)
end

function Model:updateScroll(screenHeight)
    local screenHeight = screenHeight or getView():getScreenHeight()
    local adjustedHeight = screenHeight - self.statusBarHeight  -- Adjust based on status bar height

    -- Calculate the new scroll offset based on cursor position
    if self.cursorY < self.scrollOffset + 1 then
        -- If the cursor is above the visible range, scroll up
        self.scrollOffset = math.max(0, self.cursorY - 1)
    elseif self.cursorY > self.scrollOffset + adjustedHeight then
        -- If the cursor is below the visible range, scroll down
        self.scrollOffset = math.min(self.cursorY - adjustedHeight, #self.buffer - adjustedHeight)
    end

    -- Ensure that the scroll offset stays within valid bounds
    self.scrollOffset = math.min(self.scrollOffset, math.max(0, #self.buffer - adjustedHeight))

    self:updateStatusBar("ScrollOffset: " .. self.scrollOffset .. ", CursorY: " .. self.cursorY)
end

function Model:setStatusBarHeight(height)
    self.statusBarHeight = height
end


function Model:insertChar(char)
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. char .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + 1
    self:updateStatusBar("Inserted character")
end

function Model:backspace()
    if self.cursorX > 1 then
        self:saveToHistory()
        local line = self.buffer[self.cursorY]
        self.buffer[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
        self.cursorX = self.cursorX - 1
        self:updateStatusBar("Deleted character")
    elseif self.cursorY > 1 then
        self:saveToHistory()
        local line = table.remove(self.buffer, self.cursorY)
        self.cursorY = self.cursorY - 1
        self.cursorX = #self.buffer[self.cursorY] + 1
        self.buffer[self.cursorY] = self.buffer[self.cursorY] .. line
        self:updateStatusBar("Deleted line")
        local view = getView()
    else
        self:updateStatusError("Nothing to delete")
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
    self:updateStatusBar("Inserted new line")
end

function Model:yankLine()
    self.yankRegister = self.buffer[self.cursorY]
    self:updateStatusBar("Yanked line")
end

function Model:paste()
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. self.yankRegister .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + #self.yankRegister
    self:updateStatusBar("Pasted text")
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
    self:updateStatusBar("Yanked selection")
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

    self.cursorX = startX
    self.cursorY = startY

    if startY ~= endY then
        self.buffer[startY] = self.buffer[startY] .. self.buffer[startY + 1]
        table.remove(self.buffer, startY + 1)
    end

    self:updateStatusBar("Cut selection")
end

function Model:cutLine()
    self:saveToHistory()
    self.yankRegister = self.buffer[self.cursorY]
    table.remove(self.buffer, self.cursorY)
    if self.cursorY > #self.buffer then
        self.cursorY = #self.buffer
    end
    self.cursorX = 1
    self:updateStatusBar("Cut line")
end

function Model:switchMode(mode)
    self:saveToHistory()
    self.mode = mode

    -- Close the autocomplete window if switching out of 'insert' mode
    if mode ~= "insert" and self.autocompleteWindow then
        self.autocompleteWindow:close()
        self.autocompleteWindow = nil
    end

    if mode == "insert" then
        self.InputMode = "chars"
    else
        self.InputMode = "keys"
    end

    self:updateStatusBar("Switched to " .. mode .. " mode")

    if mode == "command" then
        local commandHandler = require("CommandHandler"):getInstance()
        commandHandler:handleCommandInput(self, getView())
    end
end


function Model:saveToHistory()
    -- Deep copy the current state of the buffer, cursor positions, etc.
    table.insert(self.history, {
        buffer = table.deepCopy(self.buffer),
        cursorX = self.cursorX,
        cursorY = self.cursorY
    })
    -- Clear the redo stack since new history invalidates future redo actions
    self.redoStack = {}
end

function table.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepCopy(orig_key)] = table.deepCopy(orig_value)
        end
        setmetatable(copy, table.deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



function Model:getWordAtCursor()
    local line = self.buffer[self.cursorY]
    local startPos = self.cursorX

    -- Extend the word detection to include periods (.) and colons (:)
    while startPos > 1 and line:sub(startPos - 1, startPos - 1):match("[%w_%.:]") do
        startPos = startPos - 1
    end

    return line:sub(startPos, self.cursorX - 1)
end

-- Hardcoded autocomplete keywords
local autocompleteKeywords = {
    "and", "break", "do", "else", "elseif", "end", "for", "function", "if", "in", 
    "local", "nil", "not", "or", "repeat", "require", "return", "then", "until", 
    "while", "View", "Model", "highlightLine", "createWindow"
}

-- Helper function to get the value of a nested key
local function getNestedValue(root, pathParts)
    local current = root
    for _, part in ipairs(pathParts) do
        if type(current) == "table" and current[part] then
            current = current[part]
        else
            return nil
        end
    end
    return current
end

-- Function to get autocomplete suggestions
function Model:getAutocompleteSuggestions(prefix)
    local suggestions = {}

    -- Debugging: Show the current prefix being used for suggestions
    self:updateStatusBar("Suggestions for: " .. prefix)

    -- Handle prefix with . or :
    local pathParts = {}
    for part in prefix:gmatch("[^%.:]+") do
        table.insert(pathParts, part)
    end

    if #pathParts > 1 then
        -- We have a multi-level path like "term.r"
        local baseParts = {table.unpack(pathParts, 1, #pathParts - 1)}
        local lastPart = pathParts[#pathParts]
        local baseValue = getNestedValue(_G, baseParts)

        if type(baseValue) == "table" then
            for name, _ in pairs(baseValue) do
                if name:sub(1, #lastPart) == lastPart then
                    table.insert(suggestions, table.concat(baseParts, ".") .. "." .. name)
                end
            end
        end
    else
        -- Single level prefix or global variable/module
        -- Include static keywords only if no dot is present
        for _, keyword in ipairs(autocompleteKeywords) do
            if keyword:sub(1, #prefix) == prefix then
                table.insert(suggestions, keyword)
            end
        end

        -- Dynamic suggestions from global environment
        for name, value in pairs(_G) do
            if type(name) == "string" and name:sub(1, #prefix) == prefix then
                table.insert(suggestions, name)
            end

            -- If the value is a table, also suggest its keys
            if type(value) == "table" then
                for key in pairs(value) do
                    if type(key) == "string" and key:sub(1, #prefix) == prefix then
                        table.insert(suggestions, name .. "." .. key)
                    end
                end
            end
        end
    end

    -- Debugging: Show how many suggestions were found
    self:updateStatusBar("Suggestions for: " .. prefix .. " (" .. #suggestions .. " found)")

    return suggestions
end





return Model
