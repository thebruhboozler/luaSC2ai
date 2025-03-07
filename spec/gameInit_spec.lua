local sc2ai = require "src.sc2ai"
local ids = require "src.ids.ids"

describe("sc2ai" , function()
	describe("initialization" , function()
		it("should create and join game" , function()
			local ai = sc2ai.new("172.19.64.1" , "5000" , "test" , 1)
			ai:createGame("AbyssalReefAIE.SC2Map", 2) --auto join is set to true by default
			ai:getGameState()

			assert(#ai.units > 0 , " incorrectly parrsing the returning data")
			ai:orderMove(ai.units[2].tag,  {x = 75 , y = 75} )

			while ai.minerals < 100 do 
				ai:getGameState()
				os.execute("sleep 10")
			end
			
			ai:orderBuild(ai.units[2].tag, {x=75 , y = 75}, ids.units.SUPPLYDEPOT)
		end)
	end)
end)
