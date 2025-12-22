require "PhunZones/core"
local Core = PhunCure
local PZ = PhunZones

if PZ and PZ.fields then

    PZ.fields.cureDropRate = {
        label = "IGUI_PhunCure_CureDropRate",
        type = "int",
        tooltip = "IGUI_PhunCure_CureDropRate_Tooltip"
    }

    PZ.fields.dropRateSprinters = {
        label = "IGUI_PhunCure_DropRateSprinters",
        type = "int",
        tooltip = "IGUI_PhunCure_DropRateSprinters_Tooltip"
    }

end

