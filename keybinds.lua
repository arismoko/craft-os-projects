-- keybinds.lua

local function setupKeybinds(keyHandler, Model, View, commandHandler)
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

    keyHandler:map("normal", "u", function()
        Model:undo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "ctrl + r", function()
        Model:redo()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
    end)

    keyHandler:map("normal", "shift + ;", "switch:command")
    keyHandler:map("normal", "i", "switch:insert")
    keyHandler:map("normal", "v", "switch:visual")
    keyHandler:map("normal", "escape", function()
        Model.shouldExit = true
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
        keyHandler:map("visual", "escape", "switch:normal")
    end)

    keyHandler:map("visual", "d", function()
        Model:cutSelection()
        View:drawScreen(Model, View:getScreenWidth(), View:getScreenHeight())
        keyHandler:map("visual", "escape", "switch:normal")
    end)

    keyHandler:map("visual", "escape", "switch:normal")

    -- Insert mode keybindings
    keyHandler:map("insert", "escape", "switch:normal")
end

return setupKeybinds
