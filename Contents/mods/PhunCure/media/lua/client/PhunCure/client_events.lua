if isServer() then
    return
end
local Core = PhunCure
local PL = PhunLib
local Commands = require("PhunCure/client_commands")

local function setup()
    Events.OnTick.Remove(setup)
    Core:ini()
    sendClientCommand(Core.name, Core.commands.playerSetup, {})

end

Events.OnTick.Add(setup)

Events.OnTick.Add(function()
    Core.processQueue()
end)

if PhunSprinters then
    Events[PhunSprinters.events.onSprinterAdded].Add(function(zed)

        zed:getModData().PhunCure = nil -- remove any existing data to retest
        Core.enqueueUpdate(zed, true)

    end)
end

Events.OnZombieDead.Add(function(zed)

    local outfit = zed:getOutfitName()
    print("Zombie dead outfit: " .. tostring(outfit))
end);

Events.OnZombieUpdate.Add(function(zed)
    Core.enqueueUpdate(zed)
end)

Events.EveryTenMinutes.Add(function()
    -- periodically refresh cash of settings
    Core.settings.Debug = Core.getOption("Debug", false)
    Core.settings.MaxQueue = Core.getOption("MaxQueue", 10)
    Core.settings.DefaultDropRate = Core.getOption("DefaultDropRate", 0)
    Core.settings.DefaultSprinterDropRate = Core.getOption("DefaultSprinterDropRate", 0)
    Core.settings.MinDistance = Core.getOption("MinDistance", 400)
    Core.settings.MaxDistance = Core.getOption("MaxDistance", 3000)
end)
