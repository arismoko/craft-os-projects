local Model = require("Model"):getInstance() -- Cache the Model singleton instance

View = {}
View.__index = View

local instance

function View:new()
    if not instance then
        local screenWidth, screenHeight = term.getSize()
        instance = {
            screenWidth = screenWidth,
            screenHeight = screenHeight,
            windows = {}, -- Table to store active windows
            activeWindow = nil, -- Track the currently active window
            savedScreenBuffer = {} -- Buffer to save the current screen content
        }
        setmetatable(instance, View)
    end
    return instance
end

function View:getInstance()
    if not instance then
        instance = View:new() 
    end
    return instance
end

function View:getScreenWidth()
    return self.screenWidth
end

function View:getScreenHeight()
    return self.screenHeight
end

function View:createWindow(x, y, width, height, backgroundColor, textColor)
    -- Set default dimensions if none are provided
    width = width or (self.screenWidth - x + 1)
    height = height or (self.screenHeight - y) -- Adjust for the status bar
    
    -- Ensure window dimensions do not exceed screen size
    if x + width - 1 > self.screenWidth then
        width = self.screenWidth - x + 1
    end
    if y + height > self.screenHeight then
        height = self.screenHeight - y
    end

    local window = {
        x = x,
        y = y,
        width = width,
        height = height,
        backgroundColor = backgroundColor or colors.black,
        textColor = textColor or colors.white,
        buffer = {},
        currentLine = 1, -- Track the current line for printing
        currentColumn = 1 -- Track the current column for writing
    }

    -- Initialize the window's buffer
    for i = 1, height do
        window.buffer[i] = string.rep(" ", width)
    end

    -- Function to show the window
    function window:show()
        View:getInstance().activeWindow = self -- Set this window as the active window
        term.setBackgroundColor(self.backgroundColor)
        term.setTextColor(self.textColor)
        for i = 1, self.height do
            term.setCursorPos(self.x, self.y + i - 1)
            term.write(self.buffer[i])
        end
        term.setBackgroundColor(colors.black) -- Reset after drawing
        term.setTextColor(colors.white) -- Reset text color
    end

    -- Function to close the window (restores the main buffer)
    function window:close()
        term.clear()
        View:getInstance().activeWindow = nil -- Clear the active window
        View:getInstance():drawScreen() -- Redraw the main screen buffer
    end

    -- Function to write text at a specific position in the window
    function window:writeText(x, y, text)
        local line = self.buffer[y]
        self.buffer[y] = line:sub(1, x - 1) .. text .. line:sub(x + #text)
        self:show() -- Refresh the window display after writing
    end

    -- Function to write text continuously without a newline
    function window:write(text)
        local remainingSpace = self.width - self.currentColumn + 1
        local textToWrite = text:sub(1, remainingSpace)

        self:writeText(self.currentColumn, self.currentLine, textToWrite)
        self.currentColumn = self.currentColumn + #textToWrite

        -- Handle overflow to the next line
        if self.currentColumn > self.width then
            self.currentLine = self.currentLine + 1
            self.currentColumn = 1
        end
    end

    -- Function to write text with an automatic newline
    function window:writeline(text)
        self:write(text)
        self.currentLine = self.currentLine + 1
        self.currentColumn = 1
    end

    -- Function to clear the window's content
    function window:clear()
        for i = 1, self.height do
            self.buffer[i] = string.rep(" ", self.width)
        end
        self.currentLine = 1 -- Reset current line to the top
        self.currentColumn = 1 -- Reset current column to the start
        self:show() -- Refresh the window display after clearing
    end

    -- Function to print text on the next available line in the window
    function window:print(text)
        local lines = {}

        -- Split text by newlines to handle multi-line text
        for line in text:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        for _, line in ipairs(lines) do
            if self.currentLine > self.height then
                return -- Stop printing if we run out of space
            end
            self:writeline(line)
        end
    end

    -- Store the window in the View's windows table
    table.insert(View:getInstance().windows, window)

    return window
end

-- Function to close all windows
function View:closeAllWindows()
    for _, window in ipairs(self.windows) do
        window:close()
    end
    self.windows = {} -- Clear the windows table
    self.activeWindow = nil -- Clear the active window reference
    self:drawScreen() -- Redraw the main screen
end

function View:drawScreen()
    if self.activeWindow then
        term.clear()
        self.activeWindow:show()
        return
    else
        term.clear()
        for i = 1, self.screenHeight - 1 do
            self:drawLine(i)
        end
        self:drawStatusBar()
        term.setCursorPos(Model.cursorX, Model.cursorY - Model.scrollOffset)
        term.setCursorBlink(true)
    end
end

function View:drawLine(y)
    if type(y) ~= "number" then
        error("Invalid argument: 'y' should be a number, but received a " .. type(y))
    end
    if self.activeWindow then
        return -- Skip drawing if a window is active
    end

    local lineIndex = Model.scrollOffset + y
    term.setCursorPos(1, y)
    term.clearLine()

    if Model.buffer[lineIndex] then
        if Model.isVisualMode and Model.visualStartY and lineIndex >= math.min(Model.visualStartY, Model.cursorY) and lineIndex <= math.max(Model.visualStartY, Model.cursorY) then
            -- Highlight the selected text
            local startX = 1
            local endX = #Model.buffer[lineIndex]
            if lineIndex == Model.visualStartY then startX = Model.visualStartX end
            if lineIndex == Model.cursorY then endX = Model.cursorX end

            local beforeHighlight = Model.buffer[lineIndex]:sub(1, startX - 1)
            local highlightText = Model.buffer[lineIndex]:sub(startX, endX)
            local afterHighlight = Model.buffer[lineIndex]:sub(endX + 1)

            term.write(beforeHighlight)
            term.setBackgroundColor(colors.gray)
            term.write(highlightText)
            term.setBackgroundColor(colors.black)
            term.write(afterHighlight)
        else
            -- Draw normally without any highlight if not in visual mode
            term.write(Model.buffer[lineIndex])
        end
    end
end

function View:drawStatusBar()
    term.setCursorPos(1, self.screenHeight)
    term.setBackgroundColor(Model.statusColor)
    term.clearLine()
    term.setTextColor(colors.white)
    term.write("File: " .. Model.filename .. " | Pos: " .. Model.cursorY .. "," .. Model.cursorX)

    if Model.statusMessage ~= "" then
        term.setCursorPos(self.screenWidth - #Model.statusMessage - 1, self.screenHeight)
        term.write(Model.statusMessage)
    end

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function View:updateCursor()
    term.setCursorPos(Model.cursorX, Model.cursorY - Model.scrollOffset)
end

return View
