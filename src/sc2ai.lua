local pb = require("pb")
local protoc = require("protoc")
local connection = require("src/connection")
local debugger = require("src/debug")
local ids = require("src/ids/ids")

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
	self.vespine = 0

	self.units = {}
	self.unitComposition = {}

	self.mineralFields = {}

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
	
end

function sc2ai:getGameState()
	local gameState = self.connection:send({}, "observation").observation.observation
	self.minerals = gameState.player_common.minerals
	self.vespine = gameState.player_common.vespine
	
	for _, unit in pairs(gameState.raw_data.units) do 
		local tableToInsert
		if unit.unit_type == ids.units.MINERALFIELD then
			tableToInsert = self.mineralFields
		elseif unit.alliance == "Neutral" then 
			tableToInsert = self.miscEntities
		elseif unit.alliance == "Self" then
			tableToInsert = self.units
		elseif unit.alliance == "Enemy" then 
			tableToInsert = self.enemyUnits
		else
			error("this type of unit hasn't been implemented yet!")
		end
		table.insert(tableToInsert , unit)
	end
end

function sc2ai:orderMove(unitTag , orderTarget, queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end


	local tagExists = false
	for i = 1 , #self.units do
		if self.units[i].tag == unitTag then 
			tagExists = true
			break
		end
	end
	assert(tagExists , "No unit found with tag of " .. unitTag)

	local action = {
		action_raw = {
			unit_command = {
				ability_id = ids.abilities.MOVE_MOVE,
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

	local moveOrderRequest = {actions = {action}}

	debugger:dumpTable(self.connection:send(moveOrderRequest,"action"))
end

return sc2ai
