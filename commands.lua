-- commands.lua
local CommandHandler = require("CommandHandler"):getInstance()
local Model = require("Model"):getInstance()
local View = require("View"):getInstance()

-- Quit command
CommandHandler:map("q", function()
    Model.shouldExit = true
    Model:updateStatusBar("Exited AVIM")
end)

-- Save command
CommandHandler:map("w", function()
    Model:saveFile()
    Model:updateStatusBar("File saved")
end)

-- Find command
CommandHandler:map("find", function(_, pattern)
    if not pattern then
        Model:updateStatusError("No pattern provided for find")
        return
    end
    for y, line in ipairs(Model.buffer) do
        local startX, endX = line:find(pattern)
        if startX then
            Model.cursorY = y
            Model.cursorX = startX
            Model:updateScroll(View:getScreenHeight())
            View:drawScreen(Model)
            Model:updateStatusBar("Found '" .. pattern .. "' at line " .. y)
            return
        end
    end
    Model:updateStatusError("Pattern '" .. pattern .. "' not found")
end)

-- Replace command
CommandHandler:map("replace", function(_, oldPattern, newPattern)
    if not oldPattern or not newPattern then
        Model:updateStatusError("Usage: :replace <old> <new>")
        return
    end
    local replacements = 0
    for y, line in ipairs(Model.buffer) do
        local newLine, count = line:gsub(oldPattern, newPattern)
        if count > 0 then
            Model.buffer[y] = newLine
            replacements = replacements + count
        end
    end
    Model:updateScroll(View:getScreenHeight())
    View:drawScreen(Model)
    Model:updateStatusBar("Replaced " .. replacements .. " occurrence(s) of '" .. oldPattern .. "' with '" .. newPattern .. "'")
end)

-- Delete line command
CommandHandler:map("delete", function(_, lineNumber)
    lineNumber = tonumber(lineNumber)
    if not lineNumber or lineNumber < 1 or lineNumber > #Model.buffer then
        Model:updateStatusError("Invalid line number: " .. (lineNumber or ""))
        return
    end
    table.remove(Model.buffer, lineNumber)
    Model.cursorY = math.min(Model.cursorY, #Model.buffer)
    Model.cursorX = 1
    Model:updateScroll(View:getScreenHeight())
    View:drawScreen(Model)
    Model:updateStatusBar("Deleted line " .. lineNumber)
end)

-- Go to line command
CommandHandler:map("goto", function(_, lineNumber)
    lineNumber = tonumber(lineNumber)
    if not lineNumber or lineNumber < 1 or lineNumber > #Model.buffer then
        Model:updateStatusError("Invalid line number: " .. (lineNumber or ""))
        return
    end
    Model.cursorY = lineNumber
    Model.cursorX = 1
    Model:updateScroll(View:getScreenHeight())
    View:drawScreen(Model)
    Model:updateStatusBar("Moved to line " .. lineNumber)
end)
