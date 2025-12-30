if isServer() then
    return
end

local Core = PhunCure
local PL = PhunLib
local Commands = {}

Commands[Core.commands.hazmatZed] = function(arguments)
    Core.dressQueue[arguments.zombieId] = true
end

Commands[Core.commands.cure] = function(arguments)
    Core.debugLn("Cure command received on client with wasInfected=" .. tostring(arguments.wasInfected) ..
                     ", wasInfectedWound=" .. tostring(arguments.wasInfectedWound) .. ", wasScratched=" ..
                     tostring(arguments.wasScratched) .. ", wasBitten=" .. tostring(arguments.wasBitten))
    local player = getPlayer()
    if arguments.wasInfected or arguments.wasInfectedWound or arguments.wasScratched or arguments.wasBitten then

        if player then
            player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
            PL.addLineInChat(getText("IGUI_ItemSuccessAmpule_Success"), "<RGB:0,255,0>");
        end
    else
        if player then
            PL.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end
    end
end

return Commands
