local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"
local debugger = require "src.debug"


local ai = sc2ai.new("SimpleAttacker" , 1)
ai:createGame("AbyssalReefAIE.SC2Map", 1)


local trainingSCV = 0
local targetScv = 16 
local oldScvCount = 0
local scvCount = 0


local targetBarracks = 5
local oldBarracksCount = 0
local barracksCount = 0 
local barracksBuilding = 0

local targetSupplyDepot = 4
local supplyDepotCount = 0
local oldSupplyDepotCount = 0
local supplyDepotBuilding = 0


local targetMarrines = 30




ai:Loop(function()
	local commandCentre = ai:findUnitByType(ids.units.COMMANDCENTER)
	oldScvCount = scvCount
	scvCount = #ai:getAllUnitsOfType(ids.units.SCV)
	
	
	if ai:findUnitByType(ids.units.SUPPLYDEPOT) == nil then
		if ai.minerals < 100 then return end
		local scv = ai:findUnitByType(ids.units.SCV)
		ai:orderBuild(scv.tag, {x=commandCentre.pos.x+3 ,y=commandCentre.pos.y+3}, ids.units.SUPPLYDEPOT)
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

	local idleScvs = ai:getIdleUnitsOfType(ids.units.SCV)

	if idleScvs ~= nil then 
		for _, scv in pairs(idleScvs) do
			local mineralField = ai:findNearestUnitOfType(commandCentre.tag, ids.units.MINERALFIELD, "Neutral", "Self")
			ai:useSpecialAbility(scv.tag, ids.abilities.HARVEST_GATHER_SCV, mineralField.tag)
		end
	end

end)
