local sc2ai = require "src/sc2ai"


describe("sc2ai" , function()
	describe("initialization" , function()
		it("should create and join game" , function()
			local ai = sc2ai.new("172.19.64.1" , "5000" , "test" , 1)
			ai:createGame("AbyssalReefAIE.SC2Map", 2) --auto join is set to true by default
			ai:getGameState()

			assert(#ai.units > 0 , " incorrectly parrsing the returning data")
			ai:orderMove(ai.units[2].tag, { coords = {x = 75 , y = 75} })
		end)
	end)
end)
