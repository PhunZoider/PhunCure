PhunCure = {
    name = "PhunCure",
    consts = {},
    data = {},
    commands = {
        playerSetup = "playerSetup",
        notify = "notify",
        hazmatZed = "hazmatZed"
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

Events.EveryTenMinutes.Add(function()
    -- refresh periodically so we aren't constantly reading from function
    Core.settings.Debug = Core.getOption("Debug", false)
end)
