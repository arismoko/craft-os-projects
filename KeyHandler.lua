-- KeyHandler.lua
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
        error("KeyHandler instance has not been created yet. Call KeyHandler:new() first.")
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
    local comboKey
    if #modifiers > 0 then
        comboKey = table.concat(modifiers, "+") .. (mainKey and "+" .. mainKey or "")
    else
        comboKey = mainKey
    end

    if not self.keyMap[mode] then
        self.keyMap[mode] = {}
    end

    self.keyMap[mode][comboKey] = callback
    print("Mapped key:", comboKey, "to mode:", mode)
end

function KeyHandler:handleKeyPress(key, isDown, model, view, commandHandler)
    if self.modifierKeys[key] then
        self.keyStates[self.modifierKeys[key]] = isDown
        model:updateStatusBar("Modifier key:", keys.getName(key), "is now", isDown and "down" or "up")
    else
        local combo = {}
        if self.keyStates["ctrl"] then table.insert(combo, "ctrl") end
        if self.keyStates["shift"] then table.insert(combo, "shift") end
        if self.keyStates["alt"] then table.insert(combo, "alt") end
        table.insert(combo, keys.getName(key))
        local comboKey = table.concat(combo, "+")

        if isDown then
            local action = self.keyMap[model.mode][comboKey]
            if type(action) == "function" then
                action()
            elseif type(action) == "string" then
                if action:match("^switch:") then
                    local newMode = action:match("^switch:(.+)")
                    if newMode == "command" then
                        commandHandler:handleCommandInput(model, view)
                    else
                        model.mode = newMode
                        model.statusMessage = "Switched to " .. newMode .. " mode"
                        view:drawStatusBar(model, view:getScreenWidth(), view:getScreenHeight())
                        model:updateStatusBar("Switched to " .. newMode .. " mode")
                    end
                end
            else
                model:updateStatusBar("Unmapped key:", comboKey, "in mode:", model.mode)
            end
        end
    end
end


function KeyHandler:handleKeyEvent(mode, model, view)
    local event, key = os.pullEvent()

    if event == "key" then
        self:handleKeyPress(key, true, model, view)
    elseif event == "key_up" then
        self:handleKeyPress(key, false, model, view)
    end
end

return KeyHandler
