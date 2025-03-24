local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"

describe("sc2ai" , function()

	local ai 
	setup(function()
		os.execute("echo \"exit\" | nc " .. os.getenv("SC2IP") .. " " .. os.getenv("SC2LAUNCHPORT"))
		ai = sc2ai.new("test" , 1)
		ai:createGame("AbyssalReefAIE.SC2Map", 2) --auto join is set to true by default
	end)


	before_each(function() 
		ai:getGameState()
	end)
	
	it("should order build a supply depots #SupplyDepot",function ()
		repeat
			ai:getGameState()
			os.execute("sleep 1")
		until ai.minerals > 100
		local scvs = ai:getAllUnitsOfType(ids.units.SCV)
		local randScv = scvs[math.random(#scvs)].tag
		ai:orderBuild(randScv , {x=math.random(10) , y=math.random(10)} , ids.units.SUPPLYDEPOT)
	end)

	it("should order build a barracks #barracks",function ()
		repeat
			ai:getGameState()
			os.execute("sleep 1")
		until ai.minerals > 150

		local scvs = ai:getAllUnitsOfType(ids.units.SCV)
		local randScv = scvs[math.random(#scvs)].tag
		ai:orderBuild(randScv , {x=math.random(50) , y=math.random(50)} , ids.units.BARRACKS)
	end)


	teardown(function() 
		ai:quitGame()
	end)
end)
