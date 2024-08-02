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

    -- If there are modifiers, create nested tables for them
    if #modifiers > 0 then
        local currentMap = targetMap

        -- Create nested tables for each modifier
        for _, mod in ipairs(modifiers) do
            if not currentMap[mod] then
                currentMap[mod] = {}
            end
            currentMap = currentMap[mod]
        end

        -- Assign the callback to the final main key
        currentMap[mainKey] = callback
        print("Mapped key:", table.concat(modifiers, "+") .. "+" .. mainKey, "to mode:", mode)
    else
        -- No modifiers, assign directly
        targetMap[mainKey] = callback
        print("Mapped key:", mainKey, "to mode:", mode)
    end
end

function KeyHandler:handleKeyPress(key, isDown, model, view, commandHandler)
    local currentMap = self.keyMap[model.mode]
    
    -- Update modifier state
    if self.modifierKeys[key] then
        self.keyStates[self.modifierKeys[key]] = isDown
        return
    end

    -- Traverse keymap according to current modifier state
    if self.keyStates["ctrl"] then currentMap = currentMap.ctrl or {} end
    if self.keyStates["shift"] then currentMap = currentMap.shift or {} end
    if self.keyStates["alt"] then currentMap = currentMap.alt or {} end

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
        model:updateStatusBar("Unmapped key:", keys.getName(key), "in mode:", model.mode)
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
