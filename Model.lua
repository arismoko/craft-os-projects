-- Model.lua
Model = {}
Model.__index = Model

local instance

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
            history = {},
            redoStack = {},
            statusMessage = "",
            shouldExit = false,
            mode = "normal",
            statusColor = colors.green -- Default status bar color
        }
        setmetatable(instance, Model)
    end
    return instance
end

function Model:getInstance()
    if not instance then
        error("Model instance has not been created yet. Call Model:new() first.")
    end
    return instance
end

function Model:updateStatusBar(message, view)
    self.statusMessage = message
    self.statusColor = colors.green -- Reset to default color
    view:drawStatusBar(self, view:getScreenWidth(), view:getScreenHeight())
end

function Model:updateStatusError(message, view)
    self.statusMessage = message
    self.statusColor = colors.red -- Set color to red for errors
    view:drawStatusBar(self, view:getScreenWidth(), view:getScreenHeight())
end

function Model:clearStatusBar(view)
    self.statusMessage = ""
    self.statusColor = colors.green -- Reset to default color
    view:drawStatusBar(self, view:getScreenWidth(), view:getScreenHeight())
end

function Model:saveToHistory()
    table.insert(self.history, {
        buffer = table.deepCopy(self.buffer),
        cursorX = self.cursorX,
        cursorY = self.cursorY
    })
    self.redoStack = {}
end

function Model:undo(view)
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
        self:updateStatusBar("Undid last action", view)
    else
        self:updateStatusError("Nothing to undo", view)
    end
end

function Model:redo(view)
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
        self:updateStatusBar("Redid last action", view)
    else
        self:updateStatusError("Nothing to redo", view)
    end
end

function Model:startVisualMode(view)
    self.visualStartX = self.cursorX
    self.visualStartY = self.cursorY
    self.isVisualMode = true
    self:updateStatusBar("Entered visual mode", view)
end

function Model:endVisualMode(view)
    self.visualStartX = nil
    self.visualStartY = nil
    self.isVisualMode = false
    self:updateStatusBar("Exited visual mode", view)
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
        self:updateStatusBar("Loaded file: " .. self.filename, view)
    else
        table.insert(self.buffer, "")
        self:updateStatusError("File not found, created new file: " .. self.filename, view)
    end
end

function Model:saveFile(view)
    local file = fs.open(self.filename, "w")
    for _, line in ipairs(self.buffer) do
        file.writeLine(line)
    end
    file.close()
    self:updateStatusBar("File saved: " .. self.filename, view)
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

function Model:insertChar(char, view)
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. char .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + 1
    self:updateStatusBar("Inserted character", view)
end

function Model:backspace(view)
    if self.cursorX > 1 then
        self:saveToHistory()
        local line = self.buffer[self.cursorY]
        self.buffer[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
        self.cursorX = self.cursorX - 1
        self:updateStatusBar("Deleted character", view)
    elseif self.cursorY > 1 then
        self:saveToHistory()
        local line = table.remove(self.buffer, self.cursorY)
        self.cursorY = self.cursorY - 1
        self.cursorX = #self.buffer[self.cursorY] + 1
        self.buffer[self.cursorY] = self.buffer[self.cursorY] .. line
        self:updateStatusBar("Deleted line", view)
    else
        self:updateStatusError("Nothing to delete", view)
    end
end

function Model:enter(view)
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    local newLine = line:sub(self.cursorX)
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1)
    table.insert(self.buffer, self.cursorY + 1, newLine)
    self.cursorY = self.cursorY + 1
    self.cursorX = 1
    self:updateStatusBar("Inserted new line", view)
end

function Model:yankLine(view)
    self.yankRegister = self.buffer[self.cursorY]
    self:updateStatusBar("Yanked line", view)
end

function Model:paste(view)
    self:saveToHistory()
    local line = self.buffer[self.cursorY]
    self.buffer[self.cursorY] = line:sub(1, self.cursorX - 1) .. self.yankRegister .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + #self.yankRegister
    self:updateStatusBar("Pasted text", view)
end

function Model:yankSelection(view)
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
    self:updateStatusBar("Yanked selection", view)
end

function Model:cutSelection(view)
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

    self:updateStatusBar("Cut selection", view)
end

function Model:cutLine(view)
    self:saveToHistory()
    self.yankRegister = self.buffer[self.cursorY]
    table.remove(self.buffer, self.cursorY)
    if self.cursorY > #self.buffer then
        self.cursorY = #self.buffer
    end
    self.cursorX = 1
    self:updateStatusBar("Cut line", view)
end

return Model
