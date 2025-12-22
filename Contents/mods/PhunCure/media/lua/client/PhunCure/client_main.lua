if isServer() then
    return
end

local Core = PhunCure
local PL = PhunLib
local PZ = PhunZones

function Core.enqueueUpdate(zed, force)
    if not zed or zed:isDead() then
        return
    end

    local data = zed:getModData()
    local id = tostring(Core.getZId(zed))

    if Core.dressQueue[id] then
        -- already dressed
        Core.dressQueue[id] = nil

        zed:dressInNamedOutfit("HazardSuit")
        zed:resetModelNextFrame()
        zed:resetModel()

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

    local dx, dy = zed:getX() - player:getX(), zed:getY() - player:getY()
    local distance = dx * dx + dy * dy
    if distance < (Core.settings.MinDistance or 400) then
        -- zed is "too close" to test
        return
    elseif distance > (Core.settings.MaxDistance or 3000) then
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
        Core.queueIds[tostring(Core.getZId(zed))] = nil
        Core.testZed(zed)
        count = count + 1
    end

    if Core.settings.Debug and count == maxCount then
        print("PhunSprinters: Queue full — " .. tostring(#Core.queue) .. " more zombies waiting.")
    end
end

function Core.testZed(zed)
    local outfit = zed:getOutfitName()
    if tostring(outfit) == "HazardSuit" then
        -- already hazmat
        return
    end

    local location = nil
    local data = zed:getModData()
    location = PZ and PZ:getLocation(zed)

    local rate = tonumber(location and location.cureDropRate or Core.settings.DefaultDropRate) or 0
    local sprinterRate = tonumber(location and location.dropRateSprinters or Core.settings.DefaultSprinterDropRate) or 0
    local isSprinter = data and data.PhunSprinters and data.PhunSprinters.sprinter or false

    if rate <= 0 and not isSprinter then
        Core.debugLn("Cure drop rate is 0%.")
        return
    elseif isSprinter and sprinterRate <= 0 then
        Core.debugLn("Cure drop rate is 0%.")
        return
    elseif isSprinter then
        rate = sprinterRate
    end
    local roll = ZombRand(10000) + 1
    Core.debugLn("Roll is " .. roll .. " vs " .. rate)
    if roll <= rate then
        Core.debugLn("Zed is getting hazmat outfit.")

        sendClientCommand(Core.name, Core.commands.hazmatZed, {
            zombieId = Core.getZId(zed)
        })
        Core.dressQueue[Core.getZId(zed)] = true

        zed:dressInNamedOutfit("HazardSuit")
        zed:resetModelNextFrame()
        zed:resetModel()

    end

end
