-- View.lua
View = {}
View.__index = View

local instance

function View:new()
    if not instance then
        local screenWidth, screenHeight = term.getSize()
        instance = {
            screenWidth = screenWidth,
            screenHeight = screenHeight
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

function View:drawScreen(model)
    term.clear()
    for i = 1, self.screenHeight - 1 do
        self:drawLine(model, i)
    end
    self:drawStatusBar(model)
    term.setCursorPos(model.cursorX, model.cursorY - model.scrollOffset)
    term.setCursorBlink(true)
end

function View:drawLine(model, y)
    local lineIndex = model.scrollOffset + y
    term.setCursorPos(1, y)
    term.clearLine()

    if model.buffer[lineIndex] then
        if model.isVisualMode and model.visualStartY and lineIndex >= math.min(model.visualStartY, model.cursorY) and lineIndex <= math.max(model.visualStartY, model.cursorY) then
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

function View:drawStatusBar(model)
    term.setCursorPos(1, self.screenHeight)
    term.setBackgroundColor(model.statusColor)
    term.clearLine()
    term.setTextColor(colors.white)
    term.write("File: " .. model.filename .. " | Pos: " .. model.cursorY .. "," .. model.cursorX)

    if model.statusMessage ~= "" then
        term.setCursorPos(self.screenWidth - #model.statusMessage - 1, self.screenHeight)
        term.write(model.statusMessage)
    end

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function View:updateCursor(model)
    term.setCursorPos(model.cursorX, model.cursorY - model.scrollOffset)
end

return View
