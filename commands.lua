local function setupCommands(commands, Model, View)
    -- Quit command
    commands:map("q", function(model, view)
        model.shouldExit = true
        model:updateStatusBar("Exited AVIM", view)
    end)

    -- Save command
    commands:map("w", function(model, view)
        model:saveFile()
        model:updateStatusBar("File saved", view)
    end)

    -- Find command
    commands:map("find", function(model, view, pattern)
        if not pattern then
            model:updateStatusError("No pattern provided for find", view)
            return
        end
        for y, line in ipairs(model.buffer) do
            local startX, endX = line:find(pattern)
            if startX then
                model.cursorY = y
                model.cursorX = startX
                model:updateScroll(view:getScreenHeight())
                view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
                model:updateStatusBar("Found '" .. pattern .. "' at line " .. y, view)
                return
            end
        end
        model:updateStatusError("Pattern '" .. pattern .. "' not found", view)
    end)

    -- Replace command
    commands:map("replace", function(model, view, oldPattern, newPattern)
        if not oldPattern or not newPattern then
            model:updateStatusError("Usage: :replace <old> <new>", view)
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
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        model:updateStatusBar("Replaced " .. replacements .. " occurrence(s) of '" .. oldPattern .. "' with '" .. newPattern .. "'", view)
    end)

    -- Delete line command
    commands:map("delete", function(model, view, lineNumber)
        lineNumber = tonumber(lineNumber)
        if not lineNumber or lineNumber < 1 or lineNumber > #model.buffer then
            model:updateStatusError("Invalid line number: " .. (lineNumber or ""), view)
            return
        end
        table.remove(model.buffer, lineNumber)
        model.cursorY = math.min(model.cursorY, #model.buffer)
        model.cursorX = 1
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        model:updateStatusBar("Deleted line " .. lineNumber, view)
    end)

    -- Go to line command
    commands:map("goto", function(model, view, lineNumber)
        lineNumber = tonumber(lineNumber)
        if not lineNumber or lineNumber < 1 or lineNumber > #model.buffer then
            model:updateStatusError("Invalid line number: " .. (lineNumber or ""), view)
            return
        end
        model.cursorY = lineNumber
        model.cursorX = 1
        model:updateScroll(view:getScreenHeight())
        view:drawScreen(model, view:getScreenWidth(), view:getScreenHeight())
        model:updateStatusBar("Moved to line " .. lineNumber, view)
    end)
end

return setupCommands
