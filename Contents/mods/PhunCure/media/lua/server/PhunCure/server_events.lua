if isClient() then
    return
end
require "PhunCure/core"
local Commands = require "PhunCure/server_commands"
local Core = PhunCure

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnZombieDead.Add(function(zed)

    local outfit = zed:getOutfitName()
    if tostring(outfit) == "HazardSuit" then
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

        -- sendAddItemsToContainer(zed:getInventory(), item);
    end
end);

