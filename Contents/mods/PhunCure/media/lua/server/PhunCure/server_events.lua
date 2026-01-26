if isClient() then
    return
end
require "PhunCure/core"
local Commands = require "PhunCure/server_commands"
local Core = PhunCure
local getTimestamp = getTimestamp

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

local nextCheck = getTimestamp()
Events.OnTick.Add(function()

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
            sendServerCommand(Core.name, Core.commands.hazmatZed, vars)
            Core.toSendQueue = {}
        end
    end
end)

Events.OnZombieDead.Add(function(zed)

    local id = Core.getZId(zed)
    if Core.zIds[id] ~= nil then
        zed:dressInPersistentOutfit("HazardSuit")
        local expiredChance = Core.getOption("ExpiredChance", 0)
        if expiredChance > 0 then
            local roll = ZombRand(1, 101)
            if roll <= expiredChance then
                Core.debugLn("Zombie " .. tostring(Core.getZId(zed)) .. " dropped an expired cure (roll " ..
                                 tostring(roll) .. " <= " .. tostring(expiredChance) .. ")")
                local inventory = zed:getInventory()
                local items = zed:getInventory():AddItems("PhunCure.Cure", 1)
                for i = 0, items:size() - 1 do
                    items:get(i):setAge(items:get(i):getOffAgeMax() + ZombRand(1, 10));
                    -- sendAddItemToContainer(zed:getInventory(), items:get(i));
                end
                return
            end
        end
        local inventory = zed:getInventory()
        local item = zed:getInventory():AddItems("PhunCure.Cure", 1)

        -- zed:resetModelNextFrame()
        -- zed:resetModel()

        -- sendAddItemsToContainer(zed:getInventory(), item);

        Core.addToSend(id, nil)
    end
end);

