local debugger = {}
debugger.__index = debugger

function debugger:printStackTrace()
	local level = 1
	while true do
		local info = debug.getinfo(level, "Sl")
		if not info then break end
		print(string.format("Level %d: %s in %s", level, info.short_src, info.currentline))
		level = level + 1
	end
end

function debugger:dumpTable(t)
	local function recurse(t, indent)
		for k, v in pairs(t) do
			if type(v) == "table" then
				print(indent .. k .. " = {")
				recurse(v, indent .. "  ")
				print(indent .. "}")
			else
				print(indent .. k .. " = " .. tostring(v))
			end
		end
	end

	recurse(t, "")
end

return debugger
