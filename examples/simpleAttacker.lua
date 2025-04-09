--[[
-- A simple attacker bot 
-- then it trains 4 scvs 
-- then it builds 5 barracks 
-- and findally it trains 30 marines and orders them to attack
--]]

local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"
local debugger = require "src.debug"

math.randomseed(os.time())

local ai = sc2ai.new("SimpleAttacker" , 1)
ai:createGame("AbyssalReefAIE.SC2Map", 1)

local targetSCVs = 16
local targetBarracks = 5
local targetMarines = 30

local optimalSupplyGap = 5

local attackLaunched = false

function haveRandomUnitBuild(unit)
	local scvs = ai:getAllUnitsOfType(ids.units.SCV)
	local randSCV = scvs[math.random(#scvs)]

	local tries = 0
	local result 
	repeat
		tries = tries + 1
		local x = math.random(-15 , 15)
		local y = math.random(-15 , 15)
		result = ai:orderBuild(randSCV.tag, {x=commandCentre.pos.x+x ,y=commandCentre.pos.y+y}, unit,true)
	until result ~= true and tries <= 5 
end

ai:Loop(function()

	commandCentre = ai:findUnitByType(ids.units.COMMANDCENTER)
	local idleScvs = ai:getIdleUnitsOfType(ids.units.SCV)

	if idleScvs ~= nil then 
		for _, scv in pairs(idleScvs) do
			local mineralField = ai:findNearestUnitOfType(commandCentre.tag, ids.units.MINERALFIELD, "Neutral", "Self")
			ai:useSpecialAbility(scv.tag, ids.abilities.HARVEST_GATHER_SCV, mineralField.tag)
		end
	end


	local depotBuildingInProgess = ai:getUnitInCreationCount(ids.units.SUPPLYDEPOT) > 0
	

	local freeSupply = ai.maxSupply - ai.supply

	if freeSupply < optimalSupplyGap then
		if ai.minerals > 100 and not depotBuildingInProgess then 
			haveRandomUnitBuild(ids.units.SUPPLYDEPOT)
			return
		end
	end


	local scvCount = ai:getUnitCount(ids.units.SCV)
	local scvTrainigCount = ai:getUnitInCreationCount(ids.units.SCV)

	if (scvCount+scvTrainigCount < targetSCVs and ai.minerals >= 50) and (depotBuildingInProgess or freeSupply > 2 ) then
		ai:trainUnit(commandCentre.tag , ids.units.SCV)
		return
	end

	local barracksCount = ai:getUnitCount(ids.units.BARRACKS) 
	local barracksInCreation = ai:getUnitInCreationCount(ids.units.BARRACKS)
	if barracksCount < targetBarracks and barracksInCreation < targetBarracks and ai.minerals > 150 then
		haveRandomUnitBuild(ids.units.BARRACKS)	
		return
	end

	if barracksCount > 0 then
		optimalSupplyGap = 10
	end

	local marineCount = ai:getUnitCount(ids.units.MARINE)
	local marineTrainingCount = ai:getUnitInCreationCount(ids.units.MARINE)
	if marineCount + marineTrainingCount < targetMarines and ai.minerals >= 50 and barracksCount > 0 and (depotBuildingInProgess or freeSupply > 8 ) then
		local barracks = ai:getLeastOrderedUnitOfType(ids.units.BARRACKS)
		ai:trainUnit(barracks.tag , ids.units.MARINE)
		return 
	end

	if marineCount == targetMarines and not attackLaunched then
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
end)
