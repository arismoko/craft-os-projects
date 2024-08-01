-- keybinds.lua

local function setupKeybinds(avim, Model, View, modes)
    -- Normal mode keybindings
    avim.keys.map("normal", "up", function()
        Model.cursorY = math.max(1, Model.cursorY - 1)
        if Model:updateScroll(View:getScreenHeight()) then
            View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        else
            View:drawLine(Model, Model.cursorY - Model.scrollOffset)
        end
        View:updateCursor(Model)
    end)
    avim.keys.map("normal", "h", function()
        Model.cursorX = math.max(1, Model.cursorX - 1)
        View:updateCursor(Model)
    end)
    
    avim.keys.map("normal", "j", function()
        Model.cursorY = math.min(#Model.buffer, Model.cursorY + 1)
        if Model:updateScroll(View:getScreenHeight()) then
            View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        else
            View:drawLine(Model, Model.cursorY - Model.scrollOffset)
        end
        View:updateCursor(Model)
    end)
    
    avim.keys.map("normal", "k", function()
        Model.cursorY = math.max(1, Model.cursorY - 1)
        if Model:updateScroll(View:getScreenHeight()) then
            View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        else
            View:drawLine(Model, Model.cursorY - Model.scrollOffset)
        end
        View:updateCursor(Model)
    end)
    
    avim.keys.map("normal", "l", function()
        Model.cursorX = math.min(#Model.buffer[Model.cursorY], Model.cursorX + 1)
        View:updateCursor(Model)
    end)
        
    avim.keys.map("normal", "y", function()
        Model:yankLine()  -- Regular yank line with lowercase 'y'
    end)

    avim.keys.map("normal", "Y", function()
        Model:yankLine()  -- Yank line, but using the 'Y' uppercase for emphasis (or different action)
        Model.statusMessage = "Yanked entire line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "p", function()
        Model:paste()
        View:drawLine(Model, Model.cursorY - Model.scrollOffset)
        Model.statusMessage = "Pasted text"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "d", function()
        Model:cutLine()  -- Regular delete/cut line with lowercase 'd'
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "D", function()
        Model:cutLine()  -- Uppercase 'D' could be used for a different kind of deletion
        Model.statusMessage = "Deleted entire line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "c^ + x", function()
        Model:cutLine()
        Model.statusMessage = "Ctrl + X: Cut line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "a^ + s", function()
        Model:saveFile()
        Model.statusMessage = "Alt + S: File saved"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "s", function()
        Model:saveFile()
        Model.statusMessage = "File saved"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "i", function()
        modes.handleInsertMode(Model, View)
    end)

    avim.keys.map("normal", "q", function()
        Model.shouldExit = true  -- Set the exit flag
    end)

    avim.keys.map("normal", "v", function()
        Model:startVisualMode()
        modes.handleVisualMode(Model, View)
    end)

    -- Visual mode keybindings
    avim.keys.map("visual", "y", function()
        Model:yankSelection()
        Model:endVisualMode()
        modes.handleNormalMode(Model, View)
    end)

    avim.keys.map("visual", "d", function()
        Model:cutSelection()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        modes.handleNormalMode(Model, View)
    end)

    avim.keys.map("visual", "escape", function()
        Model:endVisualMode()
        modes.handleNormalMode(Model, View)
    end)
end

return setupKeybinds
