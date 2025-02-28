local debugger = {}
debugger.__index = debugger



function debugger:dumpTable(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. debugger:dumpTable(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

return debugger
