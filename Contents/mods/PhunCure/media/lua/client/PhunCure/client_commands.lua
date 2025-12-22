if isServer() then
    return
end

local Core = PhunCure
local Commands = {}

Commands[Core.commands.hazmatZed] = function(arguments)
    Core.dressQueue[arguments.zombieId] = true
end

return Commands
