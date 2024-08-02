-- CommandHandler.lua
CommandHandler = {}
CommandHandler.__index = CommandHandler

function CommandHandler:new()
    local instance = {
        commands = {}
    }
    setmetatable(instance, CommandHandler)
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
        model.statusMessage = "Unknown command: " .. commandName
    end
end

function CommandHandler:handleCommandInput(model, view)
    local command = ""
    model.statusMessage = ":"
    view:drawStatusBar(model)

    while true do
        local event, param1 = os.pullEvent()
        if event == "char" then
            command = command .. param1
            model.statusMessage = ":" .. command
            view:drawStatusBar(model)
        elseif event == "key" then
            if param1 == keys.enter then
                self:execute(command, model, view)
                return
            elseif param1 == keys.backspace then
                command = command:sub(1, -2)
                model.statusMessage = ":" .. command
                view:drawStatusBar(model)
            elseif param1 == keys.escape then
                return
            end
        end
    end
end

return CommandHandler
