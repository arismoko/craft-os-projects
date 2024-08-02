-- commands.lua

local function setupCommands(commands, Model, View)
    -- Quit command
    commands:map("q", function(model, view)
        model.shouldExit = true
        model.statusMessage = "Exited AVIM"
    end)

    -- Save command
    commands:map("w", function(model, view)
        model:saveFile()
    end)

    -- Find command
    commands:map("find", function(model, view, pattern)
        if not pattern then
            model.statusMessage = "No pattern provided for find"
            return
        end
        for y, line in ipairs(model.buffer) do
            local startX, endX = line:find(pattern)
            if startX then
                model.cursorY = y
                model.cursorX = startX
                model.statusMessage = "Found '" .. pattern .. "' at line " .. y
                model:updateScroll(view:getScreenHeight())
                view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
                return
            end
        end
        model.statusMessage = "Pattern '" .. pattern .. "' not found"
    end)

    -- Replace command
    commands:map("replace", function(model, view, oldPattern, newPattern)
        if not oldPattern or not newPattern then
            model.statusMessage = "Usage: :replace <old> <new>"
            return
        end
        local replacements = 0
        for y, line in ipairs(model.buffer) do
            local newLine, count = line:gsub(oldPattern, newPattern)
            if count > 0 then
                model.buffer[y] = newLine
                replacements = replacements + count
            end
        end
        model.statusMessage = "Replaced " .. replacements .. " occurrence(s) of '" .. oldPattern .. "' with '" .. newPattern .. "'"
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
    end)

    -- Delete line command
    commands:map("delete", function(model, view, lineNumber)
        lineNumber = tonumber(lineNumber)
        if not lineNumber or lineNumber < 1 or lineNumber > #model.buffer then
            model.statusMessage = "Invalid line number: " .. (lineNumber or "")
            return
        end
        table.remove(model.buffer, lineNumber)
        model.cursorY = math.min(model.cursorY, #model.buffer)
        model.cursorX = 1
        model.statusMessage = "Deleted line " .. lineNumber
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
    end)

    -- Go to line command
    commands:map("goto", function(model, view, lineNumber)
        lineNumber = tonumber(lineNumber)
        if not lineNumber or lineNumber < 1 or lineNumber > #model.buffer then
            model.statusMessage = "Invalid line number: " .. (lineNumber or "")
            return
        end
        model.cursorY = lineNumber
        model.cursorX = 1
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        model.statusMessage = "Moved to line " .. lineNumber
    end)
end

return setupCommands
