-- CommandHandler.lua
CommandHandler = {}
CommandHandler.__index = CommandHandler

local instance

function CommandHandler:new()
    if not instance then
        instance = {
            commands = {}
        }
        setmetatable(instance, CommandHandler)
    end
    return instance
end

function CommandHandler:getInstance()
    if not instance then
        instance = CommandHandler:new()
    end
    return instance
end
function CommandHandler:map(name, func)
    self.commands[name] = func
end

function CommandHandler:execute(command, model, view)
    local args = {}
    for arg in command:gmatch("%S+") do
        table.insert(args, arg)
    end

    local commandName = args[1]
    table.remove(args, 1)

    if self.commands[commandName] then
        self.commands[commandName](model, view, unpack(args))
    else
        model:updateStatusError("Unknown command: " .. commandName, view)
    end
end

function CommandHandler:handleCommandInput(model, view)
    local command = ""  -- Start with an empty command
    local firstInput = true  -- Flag to check if it's the first input
    model:updateStatusBar(":", view)  -- Display the initial ":"

    while true do
        local event, param1 = os.pullEvent()
        if event == "char" then
            if firstInput then
                firstInput = false  -- Ignore the first character and reset the flag
            else
                command = command .. param1  -- Capture input after the first character
                model:updateStatusBar(":" .. command, view)  -- Display the command prefixed with ":"
            end
        elseif event == "key" then
            if param1 == keys.enter then
                self:execute(command, model, view)  -- Execute the command when Enter is pressed
                model:switchMode("normal")  -- Switch back to normal mode
                break
            elseif param1 == keys.backspace then
                command = command:sub(1, -2)  -- Handle backspace
                model:updateStatusBar(":" .. command, view)
            elseif param1 == keys.escape then
                return  -- Exit command mode on Escape
            end
        end
    end
end


return CommandHandler
