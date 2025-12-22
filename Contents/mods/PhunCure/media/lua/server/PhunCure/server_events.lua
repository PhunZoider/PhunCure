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
        local inventory = zed:getInventory()
        local item = zed:getInventory():AddItems("PhunCure.Cure", 1)
        -- sendAddItemsToContainer(zed:getInventory(), item);
    end
end);

