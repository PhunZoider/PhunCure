if isServer() then
    return
end
local Core = PhunCure
local Commands = require("PhunCure/client_commands")
local getTimestamp = getTimestamp
local activeMods = getActivatedMods()

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

if activeMods:contains("\\phunsprinters2") and PhunSprinters then
    Events[PhunSprinters.events.onSprinterAdded].Add(function(zed)

        zed:getModData().PhunCure = nil -- remove any existing data to retest
        Core.enqueueUpdate(zed, true)

    end)
end

Events.OnZombieUpdate.Add(function(zed)
    Core.enqueueUpdate(zed)
end)

Events.EveryTenMinutes.Add(function()
    -- periodically refresh cash of settings
    Core.settings.Debug = Core.getOption("Debug", false)
    Core.settings.MaxQueue = Core.getOption("MaxQueue", 10)
    Core.settings.DefDropRate = Core.getOption("DefDropRate", "1")
    Core.settings.DefSprinterDropRate = Core.getOption("DefSprinterDropRate", "1")
    Core.settings.MinimumDistance = Core.getOption("MinimumDistance", 14)
    Core.settings.MaximumDistance = Core.getOption("MaximumDistance", 35)
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)
