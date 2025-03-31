local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"
local debugger = require "src.debug"

math.randomseed(os.time())

local ai = sc2ai.new("SimpleAttacker" , 1)
ai:createGame("AbyssalReefAIE.SC2Map", 1)


local trainingSCV = 0
local targetScv = 16 
local oldScvCount = 0
local scvCount = 0



local targetMarrines = 30
local trainingMarines = 0
local oldMarineCount = 0
local marineCount = 0

local x = 7
local y = 7


local attackLaunched = false 


ai:Loop(function()
	local commandCentre = ai:findUnitByType(ids.units.COMMANDCENTER)
	oldScvCount = scvCount
	scvCount = ai:getUnitCount(ids.units.SCV)
	
	
	if ai:getUnitCount(ids.units.SUPPLYDEPOT) < 4 then
		if ai.minerals < 100 then return end
		local scv = ai:findUnitByType(ids.units.SCV)
		ai:orderBuild(scv.tag, {x=commandCentre.pos.x+math.random(-5,5) ,y=commandCentre.pos.y+math.random(-5,5)}, ids.units.SUPPLYDEPOT)
		return
	end
	
	if scvCount-oldScvCount > 0 then
		trainingSCV = trainingSCV - 1
	end

	if targetScv > scvCount+trainingSCV then 
		if ai.minerals < 50 then return end
		local result  = ai:trainUnit(commandCentre.tag, ids.units.SCV)
		trainingSCV= trainingSCV+1
		return
	end

	if ai:getUnitCount(ids.units.BARRACKS) < 3 then
		if ai.minerals < 150 then return end
		local scv = ai:findUnitByType(ids.units.SCV)
		
		local result = ai:orderBuild(scv.tag, {x=commandCentre.pos.x+x ,y=commandCentre.pos.y+y}, ids.units.BARRACKS,true)
		while result ~= true do 
			x = math.random(-15 , 15)
			y = math.random(-15 , 15)
			result = ai:orderBuild(scv.tag, {x=commandCentre.pos.x+x ,y=commandCentre.pos.y+y}, ids.units.BARRACKS,true)
		end
		return
	end

	oldMarineCount = marineCount
	marineCount = ai:getUnitCount(ids.units.MARINE)

	if marineCount - oldMarineCount > 0 then
		trainingMarines = trainingMarines - 1
	end


	--!FIXME:implement proper counting
	if marineCount + trainingMarines < targetMarrines + 5  then 
		if ai.minerals < 50 then return end
		local barracks = ai:getLeastOrderedUnitOfType(ids.units.BARRACKS)
		if barracks.build_progress ~= 1 then return end
		local result = ai:trainUnit(barracks.tag, ids.units.MARINE)
		if result == true  then trainingMarines = trainingMarines + 1 end
		print("MarineCount " , marineCount , " training Count " , trainingMarines)
		return 
	end

	if marineCount == targetMarrines and not attackLaunched then 
		print("Launching attack")
		attackLaunched = true
		local marines = ai:getAllUnitsOfType(ids.units.MARINE)

		local attackPoint = {x=200,y=10}

		if commandCentre.pos.x > 50 and commandCentre.pos.y < 50 then
			attackPoint = {x=10 , y = 150}
		end

		for _, marine in pairs(marines) do 
			ai:orderAttack(marine.tag,attackPoint)
		end
		return 
	end

	local idleScvs = ai:getIdleUnitsOfType(ids.units.SCV)

	if idleScvs ~= nil then 
		for _, scv in pairs(idleScvs) do
			local mineralField = ai:findNearestUnitOfType(commandCentre.tag, ids.units.MINERALFIELD, "Neutral", "Self")
			ai:useSpecialAbility(scv.tag, ids.abilities.HARVEST_GATHER_SCV, mineralField.tag)
		end
	end
end)
