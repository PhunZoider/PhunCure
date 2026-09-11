if isServer() then
    return
end

local Core = PhunCure
local Commands = {}

Commands[Core.commands.cure] = function(arguments)
    Core.debugLn("Cure command received on client with wasInfected=" .. tostring(arguments.wasInfected) ..
                     ", wasInfectedWound=" .. tostring(arguments.wasInfectedWound) .. ", wasScratched=" ..
                     tostring(arguments.wasScratched) .. ", wasBitten=" .. tostring(arguments.wasBitten))
    local player = (arguments.id and getPlayerByOnlineID(arguments.id)) or getPlayer()

    -- The server cured its own copy of the character, but in multiplayer the client owns the
    -- local player's BodyDamage and keeps running the infection on it, so cure it here as well.
    -- Body part flags arrive from the server via syncBodyPart, the BodyDamage level ones do not.
    local result = {
        wasInfected = arguments.wasInfected,
        wasInfectedWound = arguments.wasInfectedWound,
        wasScratched = arguments.wasScratched,
        wasBitten = arguments.wasBitten
    }

    if isClient() and player then
        -- The server never receives the client's zombie stats and only infers
        -- BodyDamage.isInfected from the synced body part flags, so where the two copies
        -- disagree the local one is the truthful answer.
        local localResult = Core.applyCure(player)
        result.wasInfected = result.wasInfected or localResult.wasInfected
        result.wasInfectedWound = result.wasInfectedWound or localResult.wasInfectedWound
        result.wasScratched = result.wasScratched or localResult.wasScratched
        result.wasBitten = result.wasBitten or localResult.wasBitten
    end

    if player then
        if result.wasInfected or result.wasInfectedWound or result.wasScratched or result.wasBitten then
            player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_Success"), "<RGB:0,255,0>");
        else
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end

        Core.tools.sayLater(player, Core.getDiagnosis(player, result))
    end
end

return Commands
