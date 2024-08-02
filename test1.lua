-- Input Test Application

-- Table to track the state of modifier keys
local keyStates = {
    shift = false,
    ctrl = false,
    alt = false
}

-- Modifier key mapping
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
        -- Capture the key press/release and modifiers
        local combo = {}
        if keyStates["ctrl"] then table.insert(combo, "ctrl") end
        if keyStates["shift"] then table.insert(combo, "shift") end
        if keyStates["alt"] then table.insert(combo, "alt") end
        table.insert(combo, keys.getName(key))
        local comboKey = table.concat(combo, "+")

        if isDown then
            print("Key Pressed:", comboKey)
        else
            print("Key Released:", comboKey)
        end
    end
end

-- Main event loop
local function eventLoop()
    print("Starting input test. Press keys to see the output. Press 'q' to quit.")
    while true do
        local event, key = os.pullEvent()
        if event == "key" then
            handleKeyPress(key, true)
            if key == keys.q then
                print("Exiting input test.")
                break
            end
        elseif event == "key_up" then
            handleKeyPress(key, false)
        end
    end
end

-- Run the event loop
eventLoop()
