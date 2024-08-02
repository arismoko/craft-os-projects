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

function KeyHandler:handleKeyPress(key, isDown, model, view, commandHandler)
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
                    model.mode = newMode
                    model:updateStatusBar("Switched to " .. newMode .. " mode")
                end
            end
        end
    else
        model:updateStatusBar("Unmapped key: " .. keys.getName(key) .. " in mode: " .. model.mode)
    end
end

function KeyHandler:handleKeyEvent(mode, model, view, commandHandler)
    local event, key = os.pullEvent()

    if event == "key" then
        self:handleKeyPress(key, true, model, view, commandHandler)
    elseif event == "key_up" then
        self:handleKeyPress(key, false, model, view, commandHandler)
    end
end

return KeyHandler
