local pb = require("pb")
local protoc = require("protoc")
local connection = require("src.connection")
local debugger = require("src.debug")
local ids = require("src.ids.ids")
local actionHelper = require("src.actionHelper")


local sc2ai = {}
sc2ai.__index = sc2ai

function sc2ai.new(ip, port, name, race)
	assert(
		type(ip) == "string" and type(port) == "string" and type(name) == "string" and type(race) == "number",
		"wrong type of arguement passed to "
			.. debug.getinfo(1, "n").name
			.. "\n"
			.. " ip: string"
			.. " port: string "
			.. " name: string "
			.. " race: number "
	)

	local self = setmetatable({}, sc2ai)
	self.connection = connection.new(ip, port)
	self.name = name
	self.race = race

	self.minerals = 0
	self.vespene = 0

	self.units = {}
	self.unitComposition = {}

	self.mineralFields = {}
	self.vespeneGeyser = {}

	self.miscEntities = {}

	self.enemyUnits = {}
	self.enemyUnitComposition = {}

	return self
end

function sc2ai:createGame(mapPath, enemyRace, autoJoin, disableFog, randomSeed, realtime)
	if autoJoin == nil then
		autoJoin = true
	end

	if disableFog == nil then
		disableFog = false
	end

	if realtime == nil then
		realtime = true
	end

	assert(
		type(mapPath) == "string"
			and type(enemyRace) == "number"
			and type(autoJoin) == "boolean"
			and type(disableFog) == "boolean"
			and (type(randomSeed) == "number" or type(randomSeed) == "nil")
			and type(realtime) == "boolean",
		"wrong type of arguement passed to "
			.. debug.getinfo(1, "n").name
			.. "\n"
			.. " mapPath: string "
			.. " enemyRace: number "
			.. " autoJoin: boolean/nil "
			.. " disableFog: boolean/nil "
			.. " randomSeed:number/nil "
			.. " realtime: boolean/nil "
	)

	local createGameRequest = {
		local_map = { map_path = mapPath },
		player_setup = { { type = 1, race = self.race }, { type = 2, race = enemyRace } },
	}
	createGameRequest["disable_fog"] = disableFog
	if randomSeed ~= nil then createGameRequest["random_seed"] = randomSeed end
	createGameRequest["realtime"] = realtime

	self.connection:send(createGameRequest, "create_game")
	if autoJoin then
		self:joinGame()
	end
end

function sc2ai:joinGame()
	local joinGameRequest = {
		race = self.race,
		options = { raw = true },
		player_name = self.name,
	}
	self.connection:send(joinGameRequest, "join_game")
end

function generateComposition(unitTable) 
	local compTable = {}

	if #unitTable == 0 then 
		return  compTable
	end

	table.sort(unitTable, function(lUnit, rUnit)
		return lUnit.tag > rUnit.tag
		end)

	local lastTag = unitTable[1].tag
	local counter = 0
	for i = 1,#unitTable do
		local currentTag = unitTable[i].tag
		if currentTag ~= lastTag then
			table.insert(compTable, { tag = lastTag , count = counter } )
			counter = 0
			lastTag = currentTag
		else
			counter = counter +  1 
		end
	end

	--add in the last unit tag
	table.insert(compTable, { tag = lastTag , count = counter } )

	return compTable
end

function sc2ai:getGameState()
	local gameState = self.connection:send({}, "observation").observation.observation
	self.minerals = gameState.player_common.minerals
	self.vespene = gameState.player_common.vespene


	for _, unit in pairs(gameState.raw_data.units) do 
		local tabletoinsert
		if unit.unit_type == ids.units.MINERALFIELD then
			tabletoinsert = self.mineralFields
		elseif unit.unit_type == ids.units.VESPENEGEYSER then
			tabletoinsert = self.vespeneGeyser
		elseif unit.alliance == "Neutral" then 
			tabletoinsert = self.miscEntities
		elseif unit.alliance == "Self" then
			tabletoinsert = self.units
		elseif unit.alliance == "Enemy" then 
			tabletoinsert = self.enemyUnits
		else
			error("this type of unit hasn't been implemented yet!")
		end
		table.insert(tabletoinsert , unit)
	end
	self.unitComposition = generateComposition(self.units)
	self.enemyUnitComposition = generateComposition(self.enemyUnits)
end


function sc2ai:findUnitByTag(unitTag , aliance)
	
	local searchTable

	if aliance == nil or aliance == "self" then
		searchTable = self.units	
	elseif aliance == "Enemy" then
		searchTable = self.enemyUnits
	elseif aliance == "Neutral" then
		searchTable = self.miscEntities
	end

	for i=1,#searchTable do
		if searchTable[i].tag == unitTag then
			return searchTable[i]
		end
	end
	return nil 
end

function sc2ai:orderMove(unitTag , orderTarget, queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end


	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)

	local moveOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, ids.abilities.MOVE_MOVE)
	local result = self.connection:send(moveOrderRequest,"action")
	if result[1] ~= "Success" then
		return result
	end
	return true
end

function sc2ai:orderAttack(unitTag , orderTarget , queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end

	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)

	local attackOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, ids.abilities.ATTACK_ATTACK)
	local result = self.connection:send(attackOrderRequest , "action")

	if result[1] ~= "Success" then
		return result
	end
	return true
end

function sc2ai:orderBuild(unitTag , orderTarget , unitToBuildId, queueOrder )
	if queueOrder == nil then
		queueOrder = false
	end

	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)
	assert(type(orderTarget) == "table" , "orderTarget must be a poisition in world space given as a table { x , y }")

	local abilityId = actionHelper:translateToAbilityId(unitToBuildId)
	local buildOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, abilityId)
	local result = self.connection:send(buildOrderRequest, "action")
	if result[1] ~= "Success" then
		return result
	end
	return true
end

function sc2ai:cancelOrder(unitTag)

	local unit = self:findUnitByTag(unitTag)

	assert(unit ~= nil , "unable to find unit with tag of " .. unitTag)

	assert(unit.orders ~= nil , " the unitTag you have passed isn't performing any orders currrently")
	local cancelAction = actionHelper:getCancelAction(unit.orders[1])
	local cancelBuildOrderRequest = actionHelper:createRawAction(unitTag, unit.orders[1].target_world_space_pos, false , cancelAction)

	local result = self.connection:send(cancelBuildOrderRequest, "action")
	if result[1] ~= "Success" then
		return result
	end
	return true
end

function useSpecialAbility(unitTag ,abilityId , orderTarget) 

	local unit = self:findUnitByTag(unitTag)

	assert(unit ~= nil , "unable to find unit with tag of" .. unitTag)
	
	local useSpecialAbilityRequest = actionHelper:createRawAction(unitTag, orderTarget, false , abilityId)
	local result = self.connection:send(useSpecialAbilityRequest)
	if result[1] ~= "Success" then
		return result
	end
	return true
end

function sc2ai:quitGame()
	self.connection:send({}, "quit")
end

return sc2ai
