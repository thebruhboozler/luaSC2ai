local actionManager = {}
actionManager.__index=actionManager

function actionManager:createRawAction(unitTag, orderTarget, queueOrder , abilityId)

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

return actionManager
