local websocket = require "http.websocket"

local pb = require "pb"
local protoc = require "protoc"
local debugger = require "src/debug"
local timeout = 10 


--!NOTE: src is need since this going to be running from root directory
--loading the protobuf

--quick fix before I figure out how this actually works 
function importProtoAsString(path)
	local imported = {}
	
	local function hasImported(path)
		for _,val in ipairs(imported) do 
			if val == path then return true end
		end
		return false
	end


	local function mutatePath(path, line)
		local lastWord=line:match(".*/(.*)"):sub(1,-4)
		local newPath=path:match("^(.*)/").."/"..lastWord
		return newPath
	end

	local function importProtoAsStringHelper(path)
		local currStr=""
		for line in io.lines(path) do
			--need remove syntax since that's metadata
			if not line:match("^syntax") then

				--begins with import
				if line:match("^import") then 
					if not hasImported(line) then
						table.insert(imported, line)
						currStr=string.format("%s%s",currStr , importProtoAsStringHelper(mutatePath(path,line)))
					end
				else
					currStr=string.format("%s%s\n",currStr, line)
				end
			end
		end
		return currStr
	end

	return importProtoAsStringHelper(path)
end



local schema = importProtoAsString( "src/s2client-proto/s2clientprotocol/sc2api.proto")
local p = protoc.new()

p:load(schema)

local connection={}
connection.__index=connection


function connection.new(ip, port)
	local self = setmetatable({},connection)
	
	local uri = "ws://"..ip..":"..port.."/sc2api"

	self.client=websocket.new_from_uri(uri)
	assert(self.client:connect(timeout))

	return self
end


--the name for request type should match the request's varriables's definition in the protobuf 
--example: RequestCreateGame create_game -> create_game
function connection:send(request, requestType)
	local requestWrapper = {}
	requestWrapper[requestType] = request

	local protoRequest = assert(pb.encode("SC2APIProtocol.Request", requestWrapper))
	assert(self.client:send(protoRequest , 0x2, timeout))

	local pbResponseData= assert(self.client:receive(timeout))
	local responseTable= assert(pb.decode("SC2APIProtocol.Response", pbResponseData))

	if responseTable.error ~= nil then 
		print("sc2ai.connection: error in response")
		print(debugger:dumpTable(responseTable))
		assert(false)
	end
	return responseTable
end


function connection:close()
	self.client:close()
end

return connection
