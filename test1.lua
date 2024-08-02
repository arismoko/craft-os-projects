-- Input Test Application

local keys = require("keys")  -- Replace this with actual key codes for your environment

local keyStates = {
    shift = false,
    ctrl = false,
    alt = false
}

local modifierKeys = {
    [keys.leftShift] = "shift",
    [keys.rightShift] = "shift",
    [keys.leftCtrl] = "ctrl",
    [keys.rightCtrl] = "ctrl",
    [keys.leftAlt] = "alt",
    [keys.rightAlt] = "alt"
}

-- Function to handle key presses and releases
local function handleKeyPress(key, isDown)
    if modifierKeys[key] then
        -- Update the state of the modifier key (pressed or released)
        keyStates[modifierKeys[key]] = isDown
        print("Modifier key:", keys.getName(key), "is now", isDown and "down" or "up")
    else
        -- Create a combination key string
        local combo = {}
        if keyStates["ctrl"] then table.insert(combo, "ctrl") end
        if keyStates["shift"] then table.insert(combo, "shift") end
        if keyStates["alt"] then table.insert(combo, "alt") end
        table.insert(combo, keys.getName(key))
        local comboKey = table.concat(combo, "+")

        -- Print the key press
        if isDown then
            print("Key Pressed:", comboKey)
        else
            print("Key Released:", comboKey)
        end
    end
end

-- Event loop to capture key events
local function eventLoop()
    while true do
        local event, key = os.pullEvent()

        if event == "key" then
            handleKeyPress(key, true)
        elseif event == "key_up" then
            handleKeyPress(key, false)
        end
    end
end

-- Start the event loop
print("Starting Key Input Test. Press keys to see their output.")
eventLoop()