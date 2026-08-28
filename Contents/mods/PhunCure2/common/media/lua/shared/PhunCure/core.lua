PhunCure = {
    name = "PhunCure",
    commands = {
        playerSetup = "playerSetup",
        notify = "notify",
        cure = "cure"
    },
    events = {
        OnReady = "PhunCureOnReady"
    },
    settings = {},
    tools = require("PhunCure/tools")
}

local Core = PhunCure

Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:ini()
    self.inied = true
    triggerEvent(self.events.OnReady, self)
end

function Core.getOption(name, default)
    local n = Core.name .. "." .. name
    local val = getSandboxOptions():getOptionByName(n) and getSandboxOptions():getOptionByName(n):getValue()
    if val == nil then
        return default
    end
    return val
end

function Core.debugLn(str)
    if Core.settings.Debug then
        print("[" .. Core.name .. "] " .. str)
    end
end

function Core.debug(...)
    if Core.settings.Debug then
        Core.tools.debug(Core.name, ...)
    end
end

-- I suppose getOnlineID is no longer a thing in B42.17
local testForOnlineId = getCore():getGameVersion():getMajor() == 42 and getCore():getGameVersion():getMinor() < 17 and
                            (isClient() or isServer() or isCoopHost())

function Core.getZId(zed)
    if zed then
        if instanceof(zed, "IsoZombie") then
            if zed:isZombie() then

                if testForOnlineId then
                    return tostring(zed:getOnlineID())
                else
                    return tostring(zed:getID())
                end

            end
        end
    end
end

function Core.getZData(zed)
    if zed then
        local id = Core.getZId(zed)
        local data = zed:getModData()
        if not data.PhunCure then
            data.PhunCure = {
                id = id
            }
        elseif id ~= data.PhunCure.id then
            -- Possibly recycled zed
            data.PhunCure = {
                id = id
            }
        end
        return data.PhunCure
    end
    return {}
end

Core.cure = function(food, player, percent)
    if not isServer() then
        getSoundManager():PlaySound("InjectCure", false, 0):setVolume(0.50);
        if not food:isRotten() then
            sendClientCommand(player, Core.name, Core.commands.cure, {})
        else
            player:Say(getText("IGUI_ItemRottenAmpule"));
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end
    else
        Core.debugLn("Cure command received for player " .. tostring(player:getUsername()))
    end

end

-- Body part sync flags used when pushing cured body parts to the owning client.
-- BD_bitten + BD_bleeding + BD_scratched + BD_IsInfected + BD_IsFakeInfected + BD_scratchTime +
-- BD_biteTime + BD_woundInfectionLevel + BD_infectedWound + BD_bleedingTime
Core.bodyPartSyncFlags = 0x3B64C

-- Applies the cure to a character. Called on the server for its copy of the character and,
-- in multiplayer, on the owning client for its own copy (the client owns the local player's
-- BodyDamage, so a server side cure alone never reaches the player who drank it).
-- Returns what was actually cured plus the body parts that were touched.
function Core.applyCure(player)

    local result = {
        wasInfected = false,
        wasBitten = false,
        wasInfectedWound = false,
        wasScratched = false,
        parts = {}
    }

    if not player then
        return result
    end

    local bodyDamage = player:getBodyDamage()
    local stats = player:getStats()
    local bodyParts = bodyDamage:getBodyParts()

    local cureInfection = Core.getOption("CureInfection")
    local cureBite = Core.getOption("CureBite")
    local cureWound = Core.getOption("CureWound")
    local cureScratch = Core.getOption("CureScratch")

    if cureInfection and (bodyDamage:isInfected() or bodyDamage:isIsFakeInfected()) then
        -- the virus can live on BodyDamage even when no body part is still flagged
        result.wasInfected = true
    end

    for i = bodyParts:size() - 1, 0, -1 do

        local bodyPart = bodyParts:get(i)
        local changed = false
        local partWasInfected = bodyPart:IsInfected()

        if bodyPart:bitten() and cureBite then
            Core.debugLn("Curing bitten body part: " .. BodyPartType.ToString(bodyPart:getType()))
            result.wasBitten = true
            -- NOTE: the single argument BodyPart:SetBitten(false) flags the part as INFECTED again
            -- (b42 sets isInfected whenever transmission ~= 4, regardless of the argument), which is
            -- why vanilla's own debug menu clears the bite before the infection. The two argument
            -- form leaves the infection flags alone.
            bodyPart:SetBitten(false, false)
            bodyPart:setBiteTime(0)
            bodyPart:generateBleeding()
            changed = true
        end

        if bodyPart:isInfectedWound() and cureWound then
            Core.debugLn("Curing infected wound on body part: " .. BodyPartType.ToString(bodyPart:getType()))
            result.wasInfectedWound = true
            bodyPart:setWoundInfectionLevel(-1)
            changed = true
        end

        if cureScratch and bodyPart:getScratchTime() > 0 then
            Core.debugLn("Curing scratched body part: " .. BodyPartType.ToString(bodyPart:getType()))
            result.wasScratched = true
            bodyPart:setScratched(false, true)
            bodyPart:setScratchTime(0)
            changed = true
        end

        -- always last: anything above can re-flag the part as infected
        if cureInfection and (partWasInfected or bodyPart:IsInfected() or bodyPart:IsFakeInfected()) then
            if partWasInfected then
                Core.debugLn("Curing infected body part: " .. BodyPartType.ToString(bodyPart:getType()))
                result.wasInfected = true
            end
            bodyPart:SetInfected(false)
            bodyPart:SetFakeInfected(false)
            changed = true
        end

        if changed then
            table.insert(result.parts, bodyPart)
        end
    end

    if result.wasInfected then
        Core.debugLn("Removing virus")
        bodyDamage:setInfected(false)
        bodyDamage:setIsFakeInfected(false)
        bodyDamage:setReduceFakeInfection(false)
        bodyDamage:setInfectionMortalityDuration(-1)
        bodyDamage:setInfectionTime(-1)
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
        stats:set(CharacterStat.ZOMBIE_FEVER, 0)
    end

    if Core.settings.Debug then
        -- the virus is invisible in the health panel (that panel's "Infected" line is the
        -- wound infection), so report the state that actually matters
        local stillInfected = 0
        for i = bodyParts:size() - 1, 0, -1 do
            if bodyParts:get(i):IsInfected() then
                stillInfected = stillInfected + 1
            end
        end
        Core.debugLn("Post cure state: virus=" .. tostring(bodyDamage:isInfected()) .. ", fakeVirus=" ..
                         tostring(bodyDamage:isIsFakeInfected()) .. ", infectionTime=" ..
                         tostring(bodyDamage:getInfectionTime()) .. ", mortalityDuration=" ..
                         tostring(bodyDamage:getInfectionMortalityDuration()) .. ", zombieInfectionStat=" ..
                         tostring(stats:get(CharacterStat.ZOMBIE_INFECTION)) .. ", zombieFeverStat=" ..
                         tostring(stats:get(CharacterStat.ZOMBIE_FEVER)) .. ", infectedParts=" ..
                         tostring(stillInfected))
    end

    return result
end

function Core.applyFreshAndRottenDays()
    local item = ScriptManager.instance:getItem("PhunCure.Cure")
    local daysRotten = Core.getOption("DaysRotten", 5)
    local daysFresh = Core.getOption("DaysFresh", 1)

    if daysRotten <= 0 then
        daysRotten = 1000000000
    end
    item:DoParam("DaysTotallyRotten = " .. daysRotten)
    item:DoParam("DaysFresh = " .. daysFresh)
    Core.debugLn("Updated Cure item rotten days to " .. tostring(daysRotten) .. " and fresh days to " ..
                     tostring(daysFresh))
end

Events.EveryTenMinutes.Add(function()
    -- refresh periodically so we aren't constantly reading from function
    Core.settings.Debug = Core.getOption("Debug", false)
end)

Events.OnGameStart.Add(function()
    Core.applyFreshAndRottenDays()
end)

Events.OnServerStarted.Add(function()
    Core.applyFreshAndRottenDays()
end)
