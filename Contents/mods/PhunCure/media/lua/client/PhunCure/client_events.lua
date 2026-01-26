if isServer() then
    return
end
local Core = PhunCure
local PL = PhunLib
local Commands = require("PhunCure/client_commands")
local getTimestamp = getTimestamp

local function setup()
    Events.OnTick.Remove(setup)
    Core:ini()
    sendClientCommand(Core.name, Core.commands.playerSetup, {})

end

Events.OnTick.Add(setup)

local nextCheck = getTimestamp()

-- === Main OnTick Handler ===
Events.OnTick.Add(function()
    Core.processQueue()
    if getTimestamp() >= nextCheck then
        nextCheck = getTimestamp() + 1

        if #Core.toSendQueue > 0 then
            local vars = {}
            for _, v in ipairs(Core.toSendQueue) do
                if Core.zIds[v] == nil then
                    vars[v] = 0
                else
                    vars[v] = Core.zIds[v]
                end
            end
            sendClientCommand(Core.name, Core.commands.hazmatZed, vars)
            Core.toSendQueue = {}
        end
    end
end)

if PhunSprinters then
    Events[PhunSprinters.events.onSprinterAdded].Add(function(zed)

        zed:getModData().PhunCure = nil -- remove any existing data to retest
        Core.enqueueUpdate(zed, true)

    end)
end

Events.OnZombieUpdate.Add(function(zed)
    -- print("OnZombieUpdate for zed id " .. tostring(Core.getZId(zed)))
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

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)
