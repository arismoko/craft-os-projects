KeyHandler = {}
KeyHandler.__index = KeyHandler

local instance

function KeyHandler:new()
    if not instance then
        instance = {
            keyStates = {
                shift = false,
                ctrl = false,
                alt = false
            },
            currentModifierHeld = "",
            modifierKeys = {
                [keys.leftShift] = "shift",
                [keys.rightShift] = "shift",
                [keys.leftCtrl] = "ctrl",
                [keys.rightCtrl] = "ctrl",
                [keys.leftAlt] = "alt",
                [keys.rightAlt] = "alt"
            },
            keyMap = {
                normal = {},
                insert = {},
                visual = {},
                command = {}
            }
        }
        setmetatable(instance, KeyHandler)
    end
    return instance
end

function KeyHandler:getInstance()
    if not instance then
        instance = KeyHandler:new() 
    end
    return instance
end

function KeyHandler:parseKeyCombo(combo)
    local modifiers = {}
    local mainKey

    for part in combo:gmatch("[^%s+]+") do
        if part == "ctrl" or part == "shift" or part == "alt" then
            table.insert(modifiers, part)
        else
            mainKey = part
        end
    end

    return modifiers, mainKey
end

function KeyHandler:map(mode, keyCombo, callback)
    local modifiers, mainKey = self:parseKeyCombo(keyCombo)
    local targetMap = self.keyMap[mode]

    if #modifiers > 0 then
        local currentMap = targetMap

        for _, mod in ipairs(modifiers) do
            if not currentMap[mod] then
                currentMap[mod] = {}
            end
            currentMap = currentMap[mod]
        end

        currentMap[mainKey] = callback
        print("Mapped key:", table.concat(modifiers, "+") .. "+" .. mainKey, "to mode:", mode)
    else
        targetMap[mainKey] = callback
        print("Mapped key:", mainKey, "to mode:", mode)
    end
end

function KeyHandler:handleKeyEvent(model, view, commandHandler)
    local event, key = os.pullEvent()

    if event == "key" then
        self:handleKeyPress(key, true, model, view, commandHandler)
    elseif event == "key_up" then
        self:handleKeyPress(key, false, model, view, commandHandler)
    end
end

function KeyHandler:handleKeyPress(key, isDown, model, view, commandHandler)
    if model.InputMode == "keys" then
        -- Handle key bindings in normal, visual, and other non-insert modes
        if self.modifierKeys[key] then
            local modifier = self.modifierKeys[key]
            self.keyStates[modifier] = isDown

            if isDown then
                self.currentModifierHeld = modifier
                model:updateStatusBar(modifier:sub(1,1):upper() .. modifier:sub(2) .. " held, waiting for inputs")
            else
                self.currentModifierHeld = ""
                model:updateStatusBar(modifier:sub(1,1):upper() .. modifier:sub(2) .. " released with no subkey found")
            end

            return
        end

        local currentMap = self.keyMap[model.mode]

        if self.currentModifierHeld ~= "" then
            currentMap = currentMap[self.currentModifierHeld] or {}
        end

        local action = currentMap[keys.getName(key)]
        if isDown and action then
            if type(action) == "function" then
                action()
            elseif type(action) == "string" then
                if action:match("^switch:") then
                    local newMode = action:match("^switch:(.+)")
                    if newMode == "command" then
                        commandHandler:handleCommandInput(model, view)
                    else
                        model:switchMode(newMode)
                    end
                end
            end
            -- Reset the modifier after executing the action
            self.currentModifierHeld = ""
        end
    end
end

function KeyHandler:handleCharEvent(model, view)
    local firstInput = true  -- Flag to check if it's the first input

    while true do
        local event, key = os.pullEvent() -- Unified event pull

        if event == "char" then
            if firstInput then
                firstInput = false  -- Discard the first character input
            else
                self:handleCharInput(key, model, view)
                view:drawLine(model.cursorY - model.scrollOffset)
            end
        elseif event == "key" then
            if key == keys.backspace then
                model:backspace()
                view:drawLine(model.cursorY - model.scrollOffset)
                view:updateCursor()
            elseif key == keys.enter then
                model:enter()
                view:drawScreen()
                view:updateCursor()
            elseif key == keys.tab then
                model:insertChar("\t")
                view:updateCursor()
            elseif key == keys.f1 then
                model:switchMode("normal")
                break -- Exit the char mode handling loop
            end
        end
    end
end

function KeyHandler:handleCharInput(char, model, view)
    if model.InputMode == "chars" then
        -- Handle character input when in insert mode
        model:insertChar(char)
        view:updateCursor() -- Update cursor position after character insertion
    end
end

function KeyHandler:handleInputEvent(mode, model, view, commandHandler)
    if model.InputMode == "keys" then
        self:handleKeyEvent(model, view, commandHandler)
    elseif model.InputMode == "chars" then
        self:handleCharEvent(model, view)
    end
end

return KeyHandler
