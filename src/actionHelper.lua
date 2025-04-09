local ids = require("src.ids.ids")

local actionHelper = {}
actionHelper.__index=actionHelper

function actionHelper:translateToAbilityId(unitToBuildId)
	assert(type(unitToBuildId) == "number" , "unit to build must be an id")

	if unitToBuildId == ids.units.COMMANDCENTER then
		return ids.abilities.TERRANBUILD_COMMANDCENTER
	elseif unitToBuildId == ids.units.SUPPLYDEPOT then
		return ids.abilities.TERRANBUILD_SUPPLYDEPOT 
	elseif unitToBuildId == ids.units.REFINERY then
		return ids.abilities.TERRANBUILD_REFINERY 
	elseif unitToBuildId == ids.units.BARRACKS then
		return ids.abilities.TERRANBUILD_BARRACKS 
	elseif unitToBuildId == ids.units.ENGINEERINGBAY then
		return ids.abilities.TERRANBUILD_ENGINEERINGBAY 
	elseif unitToBuildId == ids.units.MISSILETURRET then
		return ids.abilities.TERRANBUILD_MISSILETURRET 
	elseif unitToBuildId == ids.units.BUNKER then
		return ids.abilities.TERRANBUILD_BUNKER 
	elseif unitToBuildId == ids.units.SENSORTOWER then
		return ids.abilities.TERRANBUILD_SENSORTOWER 
	elseif unitToBuildId == ids.units.GHOSTACADEMY then
		return ids.abilities.TERRANBUILD_GHOSTACADEMY 
	elseif unitToBuildId == ids.units.FACTORY then
		return ids.abilities.TERRANBUILD_FACTORY 
	elseif unitToBuildId == ids.units.STARPORT then
		return ids.abilities.TERRANBUILD_STARPORT 
	elseif unitToBuildId == ids.units.ARMORY then
		return ids.abilities.TERRANBUILD_ARMORY 
	elseif unitToBuildId == ids.units.FUSIONCORE then
		return ids.abilities.TERRANBUILD_FUSIONCORE 
	elseif unitToBuildId == ids.units.MARINE then 
		return ids.abilities.BARRACKSTRAIN_MARINE 
	elseif unitToBuildId == ids.units.REAPER then 
		return ids.abilities.BARRACKSTRAIN_REAPER 
	elseif unitToBuildId == ids.units.GHOST then 
		return ids.abilities.BARRACKSTRAIN_GHOST 
	elseif unitToBuildId == ids.units.MARAUDER then 
		return ids.abilities.BARRACKSTRAIN_MARAUDER 
	elseif unitToBuildId == ids.units.SIEGETANK then 
		return ids.abilities.FACTORYTRAIN_SIEGETANK 
	elseif unitToBuildId == ids.units.THOR then 
		return ids.abilities.FACTORYTRAIN_THOR 
	elseif unitToBuildId == ids.units.HELLION then 
		return ids.abilities.FACTORYTRAIN_HELLION 
	elseif unitToBuildId == ids.units.HELLBAT then 
		return ids.abilities.TRAIN_HELLBAT 
	elseif unitToBuildId == ids.units.CYCLONE then 
		return ids.abilities.TRAIN_CYCLONE 
	elseif unitToBuildId == ids.units.WIDOWMINE then 
		return ids.abilities.FACTORYTRAIN_WIDOWMINE 
	elseif unitToBuildId == ids.units.MEDIVAC then 
		return ids.abilities.STARPORTTRAIN_MEDIVAC 
	elseif unitToBuildId == ids.units.BANSHEE then 
		return ids.abilities.STARPORTTRAIN_BANSHEE 
	elseif unitToBuildId == ids.units.RAVEN then 
		return ids.abilities.STARPORTTRAIN_RAVEN 
	elseif unitToBuildId == ids.units.BATTLECRUISER then 
		return ids.abilities.STARPORTTRAIN_BATTLECRUISER 
	elseif unitToBuildId == ids.units.VIKINGFIGHTER then 
		return ids.abilities.STARPORTTRAIN_VIKINGFIGHTER 
	elseif unitToBuildId == ids.units.LIBERATOR then 
		return ids.abilities.STARPORTTRAIN_LIBERATOR 
	elseif unitToBuildId == ids.units.SCV then 
		return ids.abilities.COMMANDCENTERTRAIN_SCV
	end
end


function actionHelper:createRawAction(unitTag, orderTarget, queueOrder , abilityId)

	local action = {
		action_raw = {
			unit_command = {
				ability_id = abilityId,
				unit_tags = {unitTag},
				queue_command=queueOrder
			}
		}
	}

	if type(orderTarget) == "table" then
		action.action_raw.target = "target_world_space_pos"
		action.action_raw.unit_command.target_world_space_pos = orderTarget
	elseif type(orderTarget) == "number" then 
		action.action_raw.targetr = "target_unit_tag"
		action.action_raw.unit_command.target_unit_tag = orderTarget
	elseif type(orderTarget) ~= "nil" then
		error("orderTarget must be either an unit tag or a point in the world given as a table {x , y} ")
	end

	return {actions = { action } }
end

return actionHelper
