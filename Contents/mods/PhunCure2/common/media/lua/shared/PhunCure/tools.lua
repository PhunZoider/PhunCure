local Core = PhunCure

local ISChat = ISChat
local Calendar = Calendar
local SimpleDateFormat = SimpleDateFormat

local luautils = luautils
local loadstring = loadstring
local tools = {}

tools.isLocal = not isClient() and not isServer() and not isCoopHost()

function tools.debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            tools.printTable(v)
        else
            print(tostring(v))
        end
    end

end

function tools.printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            tools.printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

if isServer() then
    return tools
end

function tools.addLineInChat(message, color, options)

    if type(options) ~= "table" then
        options = {
            showTime = false,
            serverAlert = false,
            showAuthor = false
        };
    end

    if type(color) ~= "string" then
        color = "<RGB:1,1,1>";
    end

    if options.showTime then
        local dateStamp = Calendar.getInstance():getTime();
        local dateFormat = SimpleDateFormat.new("H:mm");
        if dateStamp and dateFormat then
            message = color .. "[" .. tostring(dateFormat:format(dateStamp) or "N/A") .. "]  " .. message;
        end
    else
        message = color .. message;
    end

    local msg = {
        getText = function(_)
            return message;
        end,
        getTextWithPrefix = function(_)
            return message;
        end,
        isServerAlert = function(_)
            return options.serverAlert;
        end,
        isShowAuthor = function(_)
            return options.showAuthor;
        end,
        getAuthor = function(_)
            return tostring(getPlayer():getDisplayName());
        end,
        setShouldAttractZombies = function(_)
            return false
        end,
        setOverHeadSpeech = function(_)
            return false
        end
    };

    if not ISChat or not ISChat.instance then
        return;
    end
    if not ISChat.instance.chatText then
        return;
    end
    ISChat.addLineInChat(msg, 0)

end

-- Queued follow up halos. Saying the diagnosis immediately would land on top of the
-- "that feels more like it" line, so it is held back a couple of seconds.
local pendingSays = {}

local function processPendingSays()
    local now = getTimestampMs()
    local remaining = {}
    for i = 1, #pendingSays do
        local entry = pendingSays[i]
        if now >= entry.due then
            if entry.player and not entry.player:isDead() then
                entry.player:Say(entry.message)
            end
        else
            remaining[#remaining + 1] = entry
        end
    end
    pendingSays = remaining
    if #pendingSays == 0 then
        Events.OnTick.Remove(processPendingSays)
    end
end

function tools.sayLater(player, message, delayMs)
    if not player or not message then
        return
    end
    pendingSays[#pendingSays + 1] = {
        player = player,
        message = message,
        due = getTimestampMs() + (delayMs or 2500)
    }
    if #pendingSays == 1 then
        Events.OnTick.Add(processPendingSays)
    end
end

return tools
