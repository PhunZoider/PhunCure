if isClient() then
    return
end
require "PhunCure/core"
local Core = PhunCure
local Commands = {}

Commands[Core.commands.cure] = function(player, arguments)

    local result = Core.applyCure(player)

    if isServer() then
        -- push the cured body parts down to the clients. The BodyDamage level flags
        -- (infected, infectionTime, mortality, stats) have no packet of their own, so the
        -- owning client re-applies the cure itself when it gets the result below.
        for _, bodyPart in ipairs(result.parts) do
            syncBodyPart(bodyPart, Core.bodyPartSyncFlags)
        end
    end

    Core.debugLn(
        "Cure command processed on server with wasInfected=" .. tostring(result.wasInfected) .. ", wasInfectedWound=" ..
            tostring(result.wasInfectedWound) .. ", wasScratched=" .. tostring(result.wasScratched) .. ", wasBitten=" ..
            tostring(result.wasBitten))

    if Core.isLocal then
        Core.debugLn("Cure command processed locally.")
        if result.wasInfected or result.wasInfectedWound or result.wasScratched or result.wasBitten then
            player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
        end
    else
        Core.debugLn("Sending cure result back to client.", result.wasInfected, result.wasInfectedWound,
            result.wasScratched, result.wasBitten)
        sendServerCommand(player, Core.name, Core.commands.cure, {
            id = player:getOnlineID(),
            wasInfected = result.wasInfected,
            wasInfectedWound = result.wasInfectedWound,
            wasScratched = result.wasScratched,
            wasBitten = result.wasBitten
        })
    end

end

return Commands
