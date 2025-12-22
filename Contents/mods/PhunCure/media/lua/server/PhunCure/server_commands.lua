if isClient() then
    return
end
require "PhunCure/core"
local Core = PhunCure
local Commands = {}

Commands[Core.commands.hazmatZed] = function(playerObj, arguments)

    if Core.pendingUpdates == nil then
        Core.pendingUpdates = {}
        Core.pendingUpdatesCount = 0
    end

    Core.pendingUpdates[arguments.zombieId] = "hazmat"
    Core.pendingUpdatesCount = Core.pendingUpdatesCount + 1
    sendServerCommand(Core.name, Core.commands.hazmatZed, {
        zombieId = arguments.zombieId
    })

end

return Commands

