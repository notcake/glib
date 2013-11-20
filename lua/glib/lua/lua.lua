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