function GLib.Lua.GetTable (tableName)
	local parts = string.Split (tableName, ".")
	
	local t = _G
	for i = 1, #parts do
		if i == 1 and parts [i] == "_R" then
			t = debug.getregistry ()
		else
			t = t [parts [i]]
		end
		
		if not t then break end
	end
	
	if not t then
		GLib.Error ("GLib.Lua.GetTable : Table " .. tableName .. " does not exist.")
		return nil
	end
	
	return t
end

function GLib.Lua.GetTableValue (valueName)
	local parts = string.Split (valueName, ".")
	local valueName = parts [#parts]
	parts [#parts] = nil
	
	local tableName = #parts > 0 and table.concat (parts, ".") or "_G"
	
	local t = _G
	for i = 1, #parts do
		if i == 1 and parts [i] == "_R" then
			t = debug.getregistry ()
		else
			t = t [parts [i]]
		end
		
		if not t then break end
	end
	
	if not t then
		GLib.Error ("GLib.Lua.GetTableValue : Table " .. tostring (tableName) .. " does not exist.")
		return nil
	end
	
	return t [valueName], t, tableName, valueName
end

local keywords =
{
	["if"]       = true,
	["then"]     = true,
	["elseif"]   = true,
	["else"]     = true,
	["for"]      = true,
	["while"]    = true,
	["do"]       = true,
	["repeat"]   = true,
	["until"]    = true,
	["end"]      = true,
	["return"]   = true,
	["break"]    = true,
	["continue"] = true,
	["function"] = true,
	["not"]      = true,
	["and"]      = true,
	["or"]       = true,
	["true"]     = true,
	["false"]    = true,
	["nil"]      = true
}

function GLib.Lua.IsValidVariableName (name)
	if not keywords [name] and string.match (name, "^[_a-zA-Z][_a-zA-Z0-9]*$") then return true end
	return false
end