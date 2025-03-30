local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"
local debugger  = require "src.debug"

describe("sc2ai" , function()

	local ai 
	setup(function()
		math.randomseed(os.time())
		os.execute("echo \"exit\" | nc " .. os.getenv("SC2IP") .. " " .. os.getenv("SC2LAUNCHPORT"))
		ai = sc2ai.new("test" , 1)
		ai:createGame("AbyssalReefAIE.SC2Map", 2) --auto join is set to true by default
	end)


	before_each(function() 
		ai:getGameState()
	end)


	local function awaitUnit(unitId)
		local unit
		while true do 
			ai:getGameState()
			unit = ai:findUnitByType(unitId)
			if unit ~= nil and unit.build_progress == 1 then 
				break
			end
			os.execute("sleep 0.1")
		end	
	end

	local function awaitMinerals(count)
		repeat
			ai:getGameState()
			os.execute("sleep 0.1")
		until ai.minerals > count
	end

	it("should build a vespeneGeyser #vespeneGeyser" , function() 
		awaitMinerals(75)
		local scvs = ai:getAllUnitsOfType(ids.units.SCV)
		local randScv = scvs[math.random(#scvs)].tag

		local nearestVespene = ai:findNearestUnitOfType(randScv,ids.units.VESPENEGEYSER , "Neutral").tag
		ai:orderBuild(randScv,nearestVespene,ids.units.REFINERY)
		awaitUnit(ids.units.REFINERY)
	end)

	it("should order build a supply depots #SupplyDepot",function ()
		awaitMinerals(100)
		local scvs = ai:getAllUnitsOfType(ids.units.SCV)
		local randScv = scvs[math.random(#scvs)].tag

		while ai:orderBuild(randScv ,{x=math.random(100) , y=math.random(100)} ,ids.units.SUPPLYDEPOT) ~= true do 
		end

		awaitUnit(ids.units.SUPPLYDEPOT)
	end)


	it("should order build a barracks #barracks",function ()
		awaitMinerals(150)

		local scvs = ai:getAllUnitsOfType(ids.units.SCV)
		local randScv = scvs[math.random(#scvs)].tag
		while ai:orderBuild(randScv , {x=math.random(50) , y=math.random(50)} , ids.units.BARRACKS) ~= true do 
		end

		awaitUnit(ids.units.BARRACKS)
	end)


	it("should train a marine at the barracks #Marine", function ()
		awaitMinerals(50)
	
		local barracks = ai:findUnitByType(ids.units.BARRACKS).tag
		ai:trainUnit(barracks, ids.units.MARINE)

		awaitUnit(ids.units.MARINE)
	end)

	it("should order a marine to attack #AttackMarine" , function()
		local marine = ai:findUnitByType(ids.units.MARINE).tag
		ai:orderAttack(marine , {x = 5 , y = 120})
		io.read()
	end)




	teardown(function() 
		ai:quitGame()
	end)
end)
