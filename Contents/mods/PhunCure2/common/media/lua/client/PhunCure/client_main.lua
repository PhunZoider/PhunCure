if isServer() then
    return
end

local Core = PhunCure
local PZ = PhunZones

function Core.enqueueUpdate(zed, force)

    if not zed or zed:isDead() then
        return
    end

    local data = zed:getModData()
    local id = tostring(Core.getZId(zed))

    if Core.dressQueue[id] or (data.PhunCure and data.PhunCure.cure and zed:getOutfitName() ~= "HazardSuit") then
        -- Not dressed
        Core.dressQueue[id] = nil
        Core.queueIds[id] = nil
        data.PhunCure = {
            id = id,
            cure = true
        }
        zed:dressInPersistentOutfit("HazardSuit")
        zed:resetModelNextFrame()
        zed:resetModel()
        return
    end

    if data.PhunCure and data.PhunCure.id == id then
        -- already checked
        return
    end
    data.PhunCure = {
        id = tostring(id)
    }

    local player = getPlayer()
    if not player or Core.queueIds[id] then
        if not force then
            -- already queued
            return
        end
    end

    local distance = 0
    if player and zed and player.DistToProper then
        distance = player:DistToProper(zed)
    end

    if distance < (Core.settings.MinimumDistance or 14) then
        -- zed is "too close" to test
        return
    elseif distance > (Core.settings.MaximumDistance or 35) then
        -- too far away
        return
    end

    Core.queueIds[id] = true
    table.insert(Core.queue, zed)
end

function Core.processQueue()
    local count = 0
    local maxCount = Core.settings.MaxQueue or 10

    while #Core.queue > 0 and count < maxCount do
        local zed = table.remove(Core.queue, 1)
        Core.queueIds[Core.getZId(zed)] = nil
        Core.testZed(zed)
        count = count + 1
    end

    if count == maxCount then
        Core.debugLn("Processed " .. tostring(count) .. " zombies, but queue is not empty. Remaining: " ..
                         tostring(#Core.queue))
    end
end

function Core.testZed(zed)
    local outfit = zed:getOutfitName()
    if tostring(outfit) == "HazardSuit" then
        -- already hazmat
        return
    end
    local id = Core.getZId(zed)
    local location = nil
    local data = zed:getModData()
    if data.PhunCure and data.PhunCure.id ~= id then
        data.PhunCure = {
            id = id
        }
    end

    location = PZ and PZ:getLocation(zed)

    local rate = math.floor((tonumber(location and location.cureDropRate or Core.settings.DefDropRate) or 0) * 100)
    local sprinterRate = math.floor((tonumber(location and location.dropRateSprinters or
                                                  Core.settings.DefSprinterDropRate) or 0) * 100)

    local isSprinter = data and data.PhunSprinters and data.PhunSprinters.sprinter or false

    if rate <= 0 and not isSprinter then
        Core.debugLn("Cure drop rate is 0%.")
        zed:transmitModData()
        return
    elseif isSprinter and sprinterRate <= 0 then
        Core.debugLn("Cure drop rate is 0%.")
        zed:transmitModData()
        return
    elseif isSprinter then
        rate = sprinterRate
    end
    local roll = ZombRand(10000) + 1
    Core.debugLn("Roll is " .. roll .. " vs " .. rate)
    if roll <= rate then
        data.PhunCure.cure = true
        Core.addToSend(id, true)
        Core.dressQueue[id] = true
    end
    zed:transmitModData()
end
