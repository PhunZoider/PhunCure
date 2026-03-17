if isClient() then
    return
end
require "PhunCure/core"
local Commands = require "PhunCure/server_commands"
local Core = PhunCure
local getTimestamp = getTimestamp

local activeMods = getActivatedMods()
local PZ = nil
if (activeMods:contains("phunzones2") or activeMods:contains("phunzones2test")) and PhunZones then
    PZ = PhunZones
end

-- Sprinter cure support: intercept PhunSprinters commands to accumulate IDs
local pendingSprinterIds = {}

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end

    if module == "PhunSprinters" and command == "isSprinter" and Core.getOption("EnableSprinterCure", false) then
        for zedId, isSprinter in pairs(arguments) do
            if isSprinter then
                pendingSprinterIds[tostring(zedId)] = true
            end
        end
    end
end)

local function makeCarrier(zed)
    zed:dressInPersistentOutfit("HazardSuit")
    zed:resetModelNextFrame()
    zed:resetModel()
    Core.debugLn("Carrier zed created")
end

-- When a zed spawns, roll the dice. Winners get dressed in hazmat.
Events.OnZombieCreate.Add(function(zed)
    if not zed then
        return
    end

    local location = PZ and PZ.getLocation and PZ.getLocation(zed) or nil
    local rate = math.floor((tonumber(location and location.cureDropRate or Core.getOption("DefDropRate", 1)) or 0) * 100)

    if rate <= 0 then
        return
    end

    local roll = ZombRand(10000) + 1
    if roll <= rate then
        makeCarrier(zed)
    end
end)

local nextSprinterCheck = getTimestamp()
Events.OnTick.Add(function()
    if not Core.getOption("EnableSprinterCure", false) then
        return
    end
    if not next(pendingSprinterIds) then
        return
    end
    if getTimestamp() < nextSprinterCheck then
        return
    end
    nextSprinterCheck = getTimestamp() + 2

    local cell = getCell()
    if not cell then
        return
    end

    local location = PZ and PZ.getLocation or nil
    local rate = math.floor((tonumber(Core.getOption("DefSprinterDropRate", 1)) or 0) * 100)
    if rate <= 0 then
        pendingSprinterIds = {}
        return
    end

    local zombies = cell:getZombieList()
    for i = 0, zombies:size() - 1 do
        local zed = zombies:get(i)
        local id = Core.getZId(zed)
        if id and pendingSprinterIds[id] then
            pendingSprinterIds[id] = nil
            -- Skip if already a carrier
            if tostring(zed:getOutfitName()) ~= "HazardSuit" then
                local loc = location and location(zed) or nil
                local r = math.floor((tonumber(loc and loc.dropRateSprinters or Core.getOption("DefSprinterDropRate", 1)) or 0) * 100)
                if r > 0 and ZombRand(10000) + 1 <= r then
                    makeCarrier(zed)
                end
            end
            if not next(pendingSprinterIds) then
                break
            end
        end
    end
end)

-- When a hazmat zed dies, add the cure to its inventory (loot is generated at death)
Events.OnZombieDead.Add(function(zed)
    if not zed or tostring(zed:getOutfitName()) ~= "HazardSuit" then
        return
    end

    local expiredChance = Core.getOption("ExpiredChance", 0)
    if expiredChance > 0 and ZombRand(1, 101) <= expiredChance then
        Core.debugLn("Carrier zed dropped expired cure")
        local item = zed:getInventory():AddItem("PhunCure.Cure")
        item:setAge(item:getOffAgeMax() + ZombRand(1, 10))
    else
        Core.debugLn("Carrier zed dropped fresh cure")
        zed:getInventory():AddItem("PhunCure.Cure")
    end
end)
