-- keybinds.lua

local function setupKeybinds(avim, Model, View, modes)
    -- Normal mode keybindings
    avim.keys.map("normal", "h", function()
        Model.cursorX = math.max(1, Model.cursorX - 1)
    end)

    avim.keys.map("normal", "j", function()
        if Model.cursorY < #Model.buffer then
            Model.cursorY = Model.cursorY + 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    end)

    avim.keys.map("normal", "k", function()
        if Model.cursorY > 1 then
            Model.cursorY = Model.cursorY - 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
    end)

    avim.keys.map("normal", "l", function()
        Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
    end)

    avim.keys.map("normal", "y", function()
        Model:yankLine()
    end)

    avim.keys.map("normal", "Y", function()
        Model:yankLine()
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
        Model:cutLine()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "D", function()
        Model:cutLine()
        Model.statusMessage = "Deleted entire line"
        View:drawStatusBar(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "x", function()
        Model:saveToHistory()
        Model:backspace()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "u", function()
        Model:undo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "ctrl + r", function()
        Model:redo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("normal", "o", function()
        Model:saveToHistory()
        Model:enter()
        modes.handleInsertMode(Model, View)
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
    avim.keys.map("visual", "h", function()
        Model.cursorX = math.max(1, Model.cursorX - 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("visual", "j", function()
        if Model.cursorY < #Model.buffer then
            Model.cursorY = Model.cursorY + 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("visual", "k", function()
        if Model.cursorY > 1 then
            Model.cursorY = Model.cursorY - 1
        end
        Model.cursorX = math.min(Model.cursorX, #Model.buffer[Model.cursorY] + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    avim.keys.map("visual", "l", function()
        Model.cursorX = math.min(#Model.buffer[Model.cursorY] + 1, Model.cursorX + 1)
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

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

    avim.keys.map("visual", "x", function()
        Model:cutSelection()  -- Similar to 'd' but perhaps for single character cuts in visual mode
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        modes.handleNormalMode(Model, View)
    end)

    avim.keys.map("visual", "o", function()
        -- Toggle visual selection mode (could be a different behavior you want to implement)
        Model:endVisualMode()
        Model:startVisualMode()
    end)

    avim.keys.map("visual", "escape", function()
        Model:endVisualMode()
        modes.handleNormalMode(Model, View)
    end)

    -- Insert mode keybindings
    avim.keys.map("insert", "escape", function()
        modes.handleNormalMode(Model, View)
    end)
end

return setupKeybinds
