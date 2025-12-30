PhunCure = {
    name = "PhunCure",
    consts = {},
    data = {},
    commands = {
        playerSetup = "playerSetup",
        notify = "notify",
        hazmatZed = "hazmatZed",
        cure = "cure"
    },
    events = {
        onReady = "PhunCureOnReady"
    },
    settings = {},
    ui = {},
    modules = {},
    queueIds = {},
    queue = {},
    dressQueue = {}
}

local Core = PhunCure
local PL = PhunLib

Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:ini()
    self.inied = true
    if not isClient() then

    end
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
        PL.debug(Core.name, ...)
    end
end

function Core.getZId(zed)
    if zed then
        if instanceof(zed, "IsoZombie") then
            if zed:isZombie() then
                if isClient() or isServer() then
                    return zed:getOnlineID()
                else
                    return zed:getID()
                end
            end
        end
    end
end

Core.cure = function(food, player, percent)
    if not isServer() then
        getSoundManager():PlaySound("InjectCure", false, 0):setVolume(0.50);
        if not food:isRotten() then
            sendClientCommand(player, Core.name, Core.commands.cure, {})
        else
            player:Say(getText("IGUI_ItemRottenAmpule"));
            PL.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end
    else
        Core.debugLn("Cure command received for player " .. tostring(player:getUsername()))
    end

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
