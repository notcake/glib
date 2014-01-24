function GLib.Lua.AddressOf (object)
	local addressString = string.format ("%p", object)
	if addressString == "NULL" then return 0 end
	return tonumber (addressString)
end

function GLib.Lua.CreateShadowGlobalTable ()
	local globalShadowTable = GLib.Lua.CreateShadowTable (_G)
	
	globalShadowTable.timer.Adjust  = GLib.NullCallback
	globalShadowTable.timer.Create  = GLib.NullCallback
	globalShadowTable.timer.Destroy = GLib.NullCallback
	globalShadowTable.timer.Pause   = GLib.NullCallback
	globalShadowTable.timer.Stop    = GLib.NullCallback
	globalShadowTable.timer.Simple  = GLib.NullCallback
	globalShadowTable.timer.Toggle  = GLib.NullCallback
	globalShadowTable.timer.UnPause = GLib.NullCallback
	
	globalShadowTable.hook.Add    = GLib.NullCallback
	globalShadowTable.hook.GetTable = function ()
		return GLib.Lua.CreateShadowTable (hook.GetTable ())
	end
	globalShadowTable.hook.Remove = GLib.NullCallback
	
	return globalShadowTable
end

function GLib.Lua.CreateShadowTable (t)
	local shadowTable = {}
	local metatable = {}
	local nils = {}
	
	metatable.__index = function (self, key)
		if rawget (self, key) ~= nil then
			return rawget (self, key)
		end
		
		if nils [key] then
			return nil
		end
		
		if t [key] ~= nil then
			if type (t [key]) == "table" then
				rawset (self, key, GLib.Lua.CreateShadowTable (t [key]))
				return rawget (self, key)
			end
			return t [key]
		end
	end
	
	metatable.__newindex = function (self, key, value)
		rawset (self, key, value)
		nils [key] = value == nil
	end
	
	setmetatable (shadowTable, metatable)
	
	return shadowTable
end

function GLib.Lua.MinifyLua (filePath)
	
end

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

local function ToLuaString (value, stringBuilder)
	local valueType = type (value)
	
	if valueType == "nil" or
	   valueType == "boolean" or
	   valueType == "number" then
		return tostring (value)
	end
	
	if valueType == "string" then
		return "\"" .. GLib.String.EscapeNonprintable (value) .. "\""
	end
	
	stringBuilder = stringBuilder or GLib.StringBuilder ()
	
	stringBuilder:Append (tostring (value))
	
	return stringBuilder
end

function GLib.Lua.ToLuaString (value)
	local luaString = ToLuaString (value, stringBuilder)
	if type (luaString) == "table" then
		luaString = luaString:ToString ()
	end
	
	return luaString
end