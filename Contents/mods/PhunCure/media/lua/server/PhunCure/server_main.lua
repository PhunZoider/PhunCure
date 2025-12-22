if isClient() then
    return
end
local Core = PhunCure
local PL = PhunLib
local PZ = PhunZones

local nextScan = 0
local SCAN_INTERVAL_MS = 500 -- tune this (250–1000ms is usually fine)

local function applyPendingZombieUpdates()

    if Core.pendingUpdates == nil then
        return
    end

    local zombies = getCell():getZombieList()
    if not zombies then
        return
    end

    for i = 0, zombies:size() - 1 do
        local z = zombies:get(i)
        if z then
            local zid = z:getOnlineID()
            local pending = Core.pendingUpdates[zid]
            if pending == "hazmat" then
                Core.debugLn("Applying hazmat to zombie " .. tostring(zid))
                z:dressInPersistentOutfit("HazardSuit")
                Core.pendingUpdates[zid] = nil
                Core.pendingUpdatesCount = Core.pendingUpdatesCount - 1
                if Core.pendingUpdatesCount <= 0 then
                    break
                end
            end
        end

    end
    Core.pendingUpdates = nil
    Core.pendingUpdatesCount = 0
end

Events.OnTick.Add(function()
    -- Only run on server
    local now = getTimestampMs()
    if now < nextScan then
        return
    end
    nextScan = now + SCAN_INTERVAL_MS

    applyPendingZombieUpdates()
end)

