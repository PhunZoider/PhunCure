require "PhunZones/core"
local Core = PhunCure
local PZ = PhunZones

local activeMods = getActivatedMods()
if not activeMods:contains("\\phunzones2") then
    if PZ and PZ.fields then

        PZ.fields.cureDropRate = {
            label = "IGUI_PhunCure_CureDropRate",
            type = "string",
            tooltip = "IGUI_PhunCure_CureDropRate_Tooltip",
            group = "mods"
        }

        if activeMods:contains("\\phunsprinters2") then

            PZ.fields.dropRateSprinters = {
                label = "IGUI_PhunCure_DropRateSprinters",
                type = "string",
                tooltip = "IGUI_PhunCure_DropRateSprinters_Tooltip",
                group = "mods"
            }
        end

    end
end
