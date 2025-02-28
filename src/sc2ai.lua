local pb = require "pb"
local protoc = require "protoc"
local connection = require "src/connection"
local debugger = require "src/debug"

local sc2ai = {}
sc2ai.__index = sc2ai



function sc2ai.new(ip, port, name , race)

	assert(type(ip) == "string" and
		type(port) == "string" and
		type(name) == "string" and 
		type(race) == "number" 
	, "wrong type of arguement passed to " .. debug.getinfo(1,"n").name .. "\n"
		.. " ip: string"  .. " port: string " .. " name: string "  .. " race: number "
	)
	

	local self=setmetatable({}, sc2ai)
	self.connection=connection.new(ip , port)
	self.name = name
	self.race = race


	self.units = {}
	self.unitComposition = {}

	self.buildings = {}
	self.buildingComposition = {}

	self.enemyBuildings = {}
	self.enemyBuildingComposition = {}

	self.enemyUnits = {}
	self.enemyUnitComposition = {}

	return self
end

function sc2ai:createGame(mapPath, enemyRace ,autoJoin , disableFog , randomSeed , realtime)

	if autoJoin == nil then 
		autoJoin = true
	end

	if disableFog == nil then 
		disableFog = false
	end

	if realtime == nil then 
		realtime = true 
	end

	assert(type(mapPath) == "string" and 
		type(enemyRace) == "number" and
		type(autoJoin) == "boolean" and 
		type(disableFog) == "boolean" and 
		(type(randomSeed) == "number" or type(randomSeed) == "nil") and
		type(realtime) == "boolean"
	, "wrong type of arguement passed to " .. debug.getinfo(1,"n").name .. "\n"
		.." mapPath: string " .. " enemyRace: number " .. " autoJoin: boolean/nil "
		.." disableFog: boolean/nil " .. " randomSeed:number/nil " .. " realtime: boolean/nil "
	)

	local createGameRequest = {
		local_map={ map_path=mapPath },
		player_setup={{type = 1 , race = self.race}, {type = 2, race=enemyRace}}
	}
	createGameRequest["disable_fog"] = disableFog 
	if randomSeed ~= nil then createGameRequest["random_seed"] = randomSeed end
	createGameRequest["realtime"] = realtime

	self.connection:send(createGameRequest,"create_game")

	if autoJoin then
		self:joinGame()
	end
end

function sc2ai:joinGame()
	local joinGameRequest = {
		race = self.race, 
		options = { raw = true },
		player_name = self.name
	}
	self.connection:send(joinGameRequest , "join_game")
end


function sc2ai:getGameState()
	local gameState = self.connection:send({}, "obeservation")
	print(debugger:dump(gameState))
end


local ai = sc2ai.new("172.19.64.1" , "5000" , "test" , 1)
ai:createGame("AbyssalReefAIE.SC2Map", 2) 
