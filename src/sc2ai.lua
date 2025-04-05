---SC2AI MODULE
-- @module sc2ai 
local socket = require("socket")
local connection = require("src.connection")
local debugger = require("src.debug")
local ids = require("src.ids.ids")
local actionHelper = require("src.actionHelper")

local sc2ai = {}
sc2ai.__index = sc2ai




--- creates sc2ai agent object 
--- @param name string name of the bot
--- @param race nmber race of the bot (1 for terran , 2 for zeg , 3 for protos and 4 for random)
--- @param ip ?string|nil ip where starcraft 2 expects the connection , if nil then it will use the environment varriable SC2IP
--- @param port ?string|nil port where starcraft 2 expects the connection  , if nil then it will use the environment varriable SC2PORT
--- @return table agent 
function sc2ai.new(name, race , ip, port)

	if ip == nil then 
		ip = assert(os.getenv("SC2IP") , "Error: Unable to determine IP! either pass the ip as string explicitly or set up SC2IP environment variable")
	end

	if port == nil then
		port = assert(os.getenv("SC2PORT") , "Error: Unable to determine port! either pass the port as string explicitly or set up SC2PORT environment variable")
	end

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
	self.supply=0
	self.maxSupply=0

	self.units = {}
	self.unitComposition = {}

	self.alliedUnits = {}
	self.alliedUnitComposition = {}

	self.mineralFields = {}
	self.vespeneGeyser = {}

	self.miscEntities = {}

	self.enemyUnits = {}
	self.enemyUnitComposition = {}
	
	self.__state = nil
	return self
end


---tells starcraft 2 to create the match 
---@param mapPath string path to the .SC2MAP file 
---@param enemyRace number race of the opponent ( 1 Terran , 2 Zerg  , 3 Protos , 4 random)
---@param autoJoin ?boolean|nil  will automatically join the game upon the match being created , by default is equal to true
---@param disableFog ?boolean|nil will disable fog , by default is equal to true
---@param randomSeed ?number|nil the seed which starcraft 2 will use , if not passed starcraft 2 will use its own seed
---@param realtime ?boolean|nil if the game should run in realtime or not (22.4 updates per second)
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

---joins game after creating it 
function sc2ai:joinGame()
	local joinGameRequest = {
		race = self.race,
		options = { raw = true },
		player_name = self.name,
	}
	self.connection:send(joinGameRequest, "join_game")
end

local function parseAlliance(self,alliance)
	if alliance == nil or alliance == "Self" then
		return self.units
	elseif alliance == "Enemy" then 
		return self.enemyUnits
	elseif alliance == "Neutral" then
		return self.miscEntities 
	elseif alliance == "Ally" then
		return self.alliedUnits
	else 
		error("Unsupported alliance type")
	end
end

--@nodoc
local function generateComposition(unitTable) 

	assert(unitTable , "unit table to generate composition is null")

	if #unitTable == 0 then 
		return {}
	end
	local compTable = {}

	table.sort(unitTable, function(lUnit, rUnit)
		return lUnit.unit_type> rUnit.unit_type
	end)	

	local lastType = unitTable[1].unit_type
	local counter = 0
	for i = 1,#unitTable do
		local currentType = unitTable[i].unit_type
		if currentType ~= lastType then
			table.insert(compTable, { type = lastType, count = counter } )
			counter = 0
			lastType = currentType
		else
			counter = counter +  1 
		end
	end
	table.insert(compTable, { type = lastType, count = counter } )
	return compTable
end
--- gets the current state of the game (meaning number of resources and all visible units)
function sc2ai:getGameState()

	local gameState = self.connection:send({}, "observation").observation.observation
	self.minerals = gameState.player_common.minerals
	self.vespene = gameState.player_common.vespene
	self.supply= gameState.player_common.food_used
	self.maxSupply = gameState.player_common.food_cap

	self.units = {}
	self.enemyUnits = {}
	self.mineralFields = {}
	self.vespeneGeyser = {}
	self.miscEntities = {}

	local tmpTable

	for _ , unit in pairs(gameState.raw_data.units) do 
		if unit.alliance == "Self" then
			tmpTable = self.units
		elseif unit.alliance =="Enemy" then
			tmpTable = self.enemyUnits
		elseif unit.unit_type == ids.units.MINERALFIELD then
			--!NOTE: since miscEntities is also for neutral I will insert them in there as well 
			-- otherwise I'd have to make "VESPENEGEYSER" and "MINERALFIELD" a separate alliance and that doesn't make logical sense 
			table.insert(self.miscEntities , unit)
			tmpTable = self.mineralFields
		elseif unit.unit_type == ids.units.VESPENEGEYSER then
			table.insert(self.miscEntities , unit)
		 	tmpTable = self.vespeneGeyser
		elseif unit.alliance == "Neutral" then
			tmpTable = self.miscEntities
		elseif unit.alliance == "Ally" then 
			tmpTable = self.alliedUnits
		else 
			error("Error: unkown type of alliance!")
		end
		table.insert(tmpTable, unit)
	end
	
	self.unitComposition = generateComposition(self.units)
	self.enemyUnitComposition = generateComposition(self.enemyUnits)
	self.alliedUnitComposition = generateComposition(self.alliedUnits)
end

---gets the number of an units visible on the map of specific type
---@param unitType number id of the unit to get
---@param alliance string the alliance of the unit "Self" for self, "Enemy" for enemies , "Ally" for allies and "Neutral" for neutral units (meaing mineral fields or barries on the map)
---@return number count the number of units found
function sc2ai:getUnitCount(unitType , alliance)
	local searchTable 
	if alliance == nil or alliance == "Self" then
		searchTable = self.unitComposition
	elseif alliance == "Enemy" then
		searchTable = self.enemyUnitComposition
	elseif alliance == "Ally" then
		searchTable = self.alliedUnitComposition
	end

	for _, unitComp in pairs(searchTable) do
		if unitComp.type == unitType then 
			return unitComp.count
		end
	end
	return 0
end

---gets unit by tag
---@param unitTag number tag of the unit
---@param alliance string the alliance of the unit "Self" for self, "Enemy" for enemies , "Ally" for allies and "Neutral" for neutral units (meaing mineral fields or barries on the map)
---@return ?table|nil unit the unit with the tag or nil if nothing is found
function sc2ai:findUnitByTag(unitTag , alliance)
	
	local searchTable

	local function concat(table1, table2)
		local res = {}
		for _,elem in pairs(table1) do
			table.insert(res,elem)
		end
		for _,elem in pairs(table2) do
			table.insert(res,elem)
		end
		return res
	end

	if alliance == nil or alliance == "Self" then
		searchTable = self.units	
	elseif alliance == "Enemy" then
		searchTable = self.enemyUnits
	elseif alliance == "Neutral" then
		searchTable = self.miscEntities
	elseif alliance == "any" then
		searchTable = concat(concat(self.units, self.enemyUnits) , concat(self.mineralFields, self.miscEntities))
	end

	for _, unit in pairs(searchTable) do
		if unit.tag == unitTag then 
			return unit
		end
	end
	return nil 
end


---orders an unit to attack 
---@param unitTag number the tag of the unit which will be moving
---@param orderTarget ?number|table the tag of the unit to be moved to or if passed as coordinates the place where to go 
---@param queueOrder ?boolean|nil queuing the order meaning doing the same thing as in base game holding shift and giving the order
---@return ?boolean|string result of the action , if successful it will return true , otherwise it will return a string stating the reason for failure
function sc2ai:orderMove(unitTag , orderTarget, queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end

	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)

	local moveOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, ids.abilities.MOVE_MOVE)
	local result = self.connection:send(moveOrderRequest,"action")
	if result.action.result[1] ~= "Success" then
		return result
	end
	return true
end


---orders an unit to attack 
---@param unitTag number the tag of the unit which will be attacking
---@param orderTarget ?number|table the tag of the unit to be attacked or if passed as coordinates the place where to attack
---@param queueOrder ?boolean|nil queuing the order meaning doing the same thing as in base game holding shift and giving the order
---@return ?boolean|string result of the action , if successful it will return true , otherwise it will return a string stating the reason for failure
function sc2ai:orderAttack(unitTag , orderTarget , queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end

	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)

	local attackOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, ids.abilities.ATTACK_ATTACK)
	local result = self.connection:send(attackOrderRequest , "action")
	if result.action.result[1] ~= "Success" then
		return result
	end
	return true
end

---orders a worker to build a structure
---@param unitTag number the tag of the unit which will build
---@param orderTarget ?table|number tag of the unit on which the structure will be built, if passed as a coordinate table { x , y } the place where the building will be built
---@param unitToBuildId number the id of the type of unit to be built
---@param queueOrder ?boolean|nil queuing the order meaning doing the same thing as in base game holding shift and giving the order
---@return ?boolean|string result of the action , if successful it will return true , otherwise it will return a string stating the reason for failure
function sc2ai:orderBuild(unitTag , orderTarget ,  unitToBuildId , queueOrder)
	if queueOrder == nil then
		queueOrder = false
	end

	assert(self:findUnitByTag(unitTag) ~= nil , "unable to find unit with tag of " .. unitTag)
	assert(type(orderTarget) == "table" or type(orderTarget) == "number" , "orderTarget must either be an unit tag or a poisition in world space given as a table { x , y }")

	local abilityId = actionHelper:translateToAbilityId(unitToBuildId)
	local buildOrderRequest = actionHelper:createRawAction(unitTag, orderTarget, queueOrder, abilityId)
	local result = self.connection:send(buildOrderRequest, "action")
	if result.action.result[1] ~= "Success" then
		return result.action.result[1]
	end
	return true
end

---Uses special ability 
---@param unitTag number the tag of the unit using the ability
---@param abilityId number the id of the ability that is to be used 
---@param orderTarget ?table|number tag of the unit on which the ability is to be used , if passed as a coordinate table { x , y } the place where the ability will be targeted 
---@return ?boolean|string result of the action , if successful it will return true , otherwise it will return a string stating the reason for failure
function sc2ai:useSpecialAbility(unitTag ,abilityId , orderTarget) 
	local unit = self:findUnitByTag(unitTag)

	assert(unit ~= nil , "unable to find unit with tag of" .. unitTag)
	
	local useSpecialAbilityRequest = actionHelper:createRawAction(unitTag, orderTarget, false , abilityId)
	local result = self.connection:send(useSpecialAbilityRequest, "action")
	if result.action.result[1] ~= "Success" then
		return result
	end
	return true
end

---Trains an unit
---@param trainerTag number the tag of the trainer unit
---@param unitId number the id of the type of unit which is to be trained
---@return ?boolean|string result of the action , if successful it will return true , otherwise it will return a string stating the reason for failure
function sc2ai:trainUnit(trainerTag , unitId)
	local unit = self:findUnitByTag(trainerTag)
	assert(unit ~= nil , "unable to find unit with tag of " .. trainerTag)
	assert(unit.unit_type == ids.units.BARRACKS 
		or unit.unit_type == ids.units.COMMANDCENTER
		or unit.unit_type == ids.units.FACTORY
		or unit.unit_type == ids.units.STARPORT,
		"unit is not able to train")

	local abilityId = actionHelper:translateToAbilityId(unitId)
	local trainRequest = actionHelper:createRawAction(trainerTag, nil , true,abilityId)
	local result = self.connection:send(trainRequest,"action")
	if result.action.result[1] ~= "Success" then
		return result
	end
	return true
end


---main loop for running the behaviour of the agent
---@param callback function the callback function where the behaviour of the agent is defined
function sc2ai:Loop(callback)
	--!FIXME: do this correctly ! await the start of the game from start of countdown
	socket.sleep(4)
	local stepInterval = 1/22.4
	while true do
		local startTime = socket.gettime()
		self:getGameState()
		callback()
		local duration = socket.gettime() - startTime
		local timeTilNextStep = stepInterval - duration
		if timeTilNextStep > 0 then 
			socket.sleep(timeTilNextStep)
		end
	end
end

---finds a single unit 
---@param unitType number id of the unit type
---@param alliance string the alliance of the unit being searched for "Self" for self, "Enemy" for enemies , "Ally" for allies and "Neutral" for neutral units (meaing mineral fields or barries on the map)
---@return ?table|nil unit a single unit of the type or nil if none are found
function sc2ai:findUnitByType(unitType, alliance)
	local searchTable = parseAlliance(self,alliance)
	for _,unit in pairs(searchTable) do 
		if unitType == unit.unit_type then
			return unit
		end
	end
	return nil
end

---gets all units of a type
---@param unitType number id of the unit type
---@param alliance string the alliance of the unit being searched for "Self" for self, "Enemy" for enemies , "Ally" for allies and "Neutral" for neutral units (meaing mineral fields or barries on the map)
---@return ?table|nil units a table of units of the type or nil if none are found
function sc2ai:getAllUnitsOfType(unitType , alliance)
	local searchTable = parseAlliance(self,alliance)
	local res = {}

	for _, unit in pairs(searchTable) do
		if unit.unit_type == unitType then 
			table.insert(res , unit)
		end
	end

	if #res >0 then 
		return res 
	end
	return nil
end

---finds the neartest unit of type from a point or an unit
---@param target ?table|number the coordinates { x , y } or a tag of an unit , if passed in as a tag it will use the units coordinatesand find the neartest to it 
---@param unitType number which type of an unit to find
---@param alliance string the alliance of the unit being searched for "Self" for self, "Enemy" for enemies , "Ally" for allies and "Neutral" for neutral units (meaing mineral fields or barries on the map)
---@param targetAlliance ?string|nil the alliance of the unit we are searching from , if the target is given as a table of coordinates then this parameter is ignored 
---@return ?table|nil the nearest unit found or nil if no unit found
function sc2ai:findNearestUnitOfType(target , unitType, alliance , targetAlliance)
	if type(target) ~= "table" then 
		local unit = self:findUnitByTag(target, targetAlliance)
		target = {x = unit.pos.x , y = unit.pos.y}
	end

	local function getDist(x1,y1, x2,y2)
		return math.sqrt((x1-x2) * (x1-x2) + (y1-y2)*(y1-y2))
	end

	local searchTable = parseAlliance(self,alliance)

	local minUnit = nil
	local minDist = math.huge
	for _, unit in pairs(searchTable) do
		if unit.unit_type == unitType then
			local dist =getDist(target.x, target.y, unit.pos.x, unit.pos.y) 
			if dist < minDist then
				minDist = dist
				minUnit = unit
			end
		end
	end

	return minUnit
end

---gets the unit with the lowest number of orders of a certain type 
---@param unitType number the type of the unit
---@return table unit the unit with the lowest number of orders
function sc2ai:getLeastOrderedUnitOfType(unitType)
	local minUnit = nil
	local minOrders = math.huge
	for _, unit in pairs(self.units) do
		if unit.unit_type == unitType then
			if unit.orders == nil then 
				return unit
			end
			if minOrders > #unit.orders then
				minOrders = #unit.orders
				minUnit = unit
			end
		end
	end
	return minUnit
end

---gets all ide Units of a type
---@param unitType number the type of the unit
---@return ?table|nil an array of all idle units , if no idle units exist it returns nil
function sc2ai:getIdleUnitsOfType(unitType)
	local res = {}		
	for _, unit in pairs(self.units) do
		if unit.unit_type == unitType and unit.orders == nil then
			table.insert(res, unit)
		end
	end
	if #res > 0 then 
		return res
	end
	return nil
end

---gets all ide Units
---@return ?table|nil an array of all idle units , if no idle units exist it returns nil
function sc2ai:getIdleUnits()
	local res = {}		
	for _, unit in pairs(self.units) do
		if #unit.orders == 0 then
			table.insert(res, unit)
		end
	end
	if #res > 0 then 
		return res
	end
	return nil
end
---quits the game and forces starcraft 2 to shutdown
function sc2ai:quitGame()
	self.connection:send({}, "quit")
end

return sc2ai
