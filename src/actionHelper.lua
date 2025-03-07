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
		action.action_raw.unit_command.target_world_space_pos = orderTarget
	elseif type(orderTarget) == "number" then 
		action.action_raw.unit_command.target_unit_tag = orderTarget
	else
		error("orderTarget must be either an unit tag or a point in the world given as a table {x , y} ")
	end

	return {actions = { action } }
end

function actionHelper:getCancelAction(action)
	assert(type(action) == "number" , "action must be an id")

	if action >= ids.actions.TERRANBUILD_COMMANDCENTER and action <= ids.abilities.TERRANBUILD_FUSIONCORE then 
		return ids.actions.HALT_TERRANBUILD
	elseif action == ids.actions.MOVE_MOVE then
		return ids.actions.STOP_STOP
	else 
		error("this action doesn't have an opposite action")
	end
end

return actionHelper
