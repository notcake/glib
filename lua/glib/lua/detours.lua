function GLib.Lua.Detour (functionName, detourFunction)
	local originalFunction, table, tableName, functionName = GLib.Lua.GetTableValue (functionName)
	
	GLib.Lua.Backup (tableName, functionName, originalFunction)
	
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	table [functionName] = function (...)
		return detourFunction (backupTable [functionName], ...)
	end
end

function GLib.Lua.Undetour (functionName)
	local _, table, tableName, functionName = GLib.Lua.GetTableValue (functionName)
	table [functionName] = GLib.Lua.GetBackup (tableName, functionName) or table [functionName]
end