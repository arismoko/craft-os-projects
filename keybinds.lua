-- keybinds.lua

local function setupKeybinds(keyHandler, Model, View, modes)
    -- Normal mode keybindings
    keyHandler:map("normal", "h", function()
        Model.cursorX = math.max(1, Model.cursorX - 1)
    end)

    keyHandler:map("normal", "j", function()
        if Model.cursorY < #Model.buffer then
            Model.cursorY = Model.cursorY + 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    end)

    keyHandler:map("normal", "k", function()
        if Model.cursorY > 1 then
            Model.cursorY = Model.cursorY - 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    end)

    keyHandler:map("normal", "l", function()
        Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
    end)

    keyHandler:map("normal", "y", function()
        Model:yankLine()
    end)

    keyHandler:map("normal", "Y", function()
        Model:yankLine()
        Model.statusMessage = "Yanked entire line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "p", function()
        Model:paste()
        View:drawLine(Model, Model.cursorY - Model.scrollOffset)
        Model.statusMessage = "Pasted text"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "d", function()
        Model:cutLine()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "D", function()
        Model:cutLine()
        Model.statusMessage = "Deleted entire line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "x", function()
        Model:saveToHistory()
        Model:backspace()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "u", function()
        Model:undo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "ctrl + r", function()
        Model:redo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "o", function()
        Model:saveToHistory()
        Model:enter()
        modes.handleInsertMode(Model, View)
    end)

    keyHandler:map("normal", "c^ + x", function()
        Model:cutLine()
        Model.statusMessage = "Ctrl + X: Cut line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "a^ + s", function()
        Model:saveFile()
        Model.statusMessage = "Alt + S: File saved"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "s", function()
        Model:saveFile()
        Model.statusMessage = "File saved"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "i", function()
        modes.handleInsertMode(Model, View)
    end)

    keyHandler:map("normal", "q", function()
        Model.shouldExit = true  -- Set the exit flag
    end)

    keyHandler:map("normal", "v", function()
        Model:startVisualMode()
        modes.handleVisualMode(Model, View)
    end)

    -- Visual mode keybindings
    keyHandler:map("visual", "h", function()
        Model.cursorX = math.max(1, Model.cursorX - 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("visual", "j", function()
        if Model.cursorY < #Model.buffer then
            Model.cursorY = Model.cursorY + 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("visual", "k", function()
        if Model.cursorY > 1 then
            Model.cursorY = Model.cursorY - 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("visual", "l", function()
        Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("visual", "y", function()
        Model:yankSelection()
        Model:endVisualMode()
        modes.handleNormalMode(Model, View)
    end)

    keyHandler:map("visual", "d", function()
        Model:cutSelection()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        modes.handleNormalMode(Model, View)
    end)

    keyHandler:map("visual", "x", function()
        Model:cutSelection()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        modes.handleNormalMode(Model, View)
    end)

    keyHandler:map("visual", "o", function()
        Model:endVisualMode()
        Model:startVisualMode()
    end)

    keyHandler:map("visual", "escape", function()
        Model:endVisualMode()
        modes.handleNormalMode(Model, View)
    end)

    -- Insert mode keybindings
    keyHandler:map("insert", "escape", function()
        modes.handleNormalMode(Model, View)
    end)
end

return setupKeybinds
