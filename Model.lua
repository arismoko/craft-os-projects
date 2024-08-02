-- Model.lua
Model = {}
Model.__index = Model

function Model:new()
    local instance = {
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
        mode = "normal"
    }
    setmetatable(instance, Model)
    return instance
end

function Model:saveToHistory()
    table.insert(self.history, {
        buffer = table.deepCopy(self.buffer),
        cursorX = self.cursorX,
        cursorY = self.cursorY
    })
    self.redoStack = {}
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
        self.statusMessage = "Undid last action"
    else
        self.statusMessage = "Nothing to undo"
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

    self.cursorX = startX
    self.cursorY = startY

    if startY ~= endY then
        self.buffer[startY] = self.buffer[startY] .. self.buffer[startY + 1]
        table.remove(self.buffer, startY + 1)
    end

    self.statusMessage = "Cut selection"
end

function Model:cutLine()
    self:saveToHistory()
    self.yankRegister = self.buffer[self.cursorY]
    table.remove(self.buffer, self.cursorY)
    if self.cursorY > #self.buffer then
        self.cursorY = #self.buffer
    end
    self.cursorX = 1
    self.statusMessage = "Cut line"
end

return Model
