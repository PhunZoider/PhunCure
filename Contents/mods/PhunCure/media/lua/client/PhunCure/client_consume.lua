local Core = PhunCure
Core.cure = {
    onEat = function(food, player, percent)
        if not food:isRotten() then

            local food = food
            local character = player
            local percent = percent
            local playerdata = character:getModData()
            local bodyDamage = character:getBodyDamage();
            bodyDamage:setInfected(false);
            bodyDamage:setInfectionMortalityDuration(-1);

            local bodyParts = bodyDamage:getBodyParts();
            local wasInfected = false
            for i = bodyParts:size() - 1, 0, -1 do
                local bodyPart = bodyParts:get(i);
                if bodyPart:IsInfected() then
                    wasInfected = true
                end
                bodyPart:SetBitten(false);
                bodyPart:SetInfected(false);
                bodyPart:SetFakeInfected(false);

            end
            bodyDamage:setInfected(false);

            if wasInfected then
                player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
            end
        else
            if isClient() then
                player():Say(getText("IGUI_ItemRottenAmpule"));
            end
        end

    end
}

