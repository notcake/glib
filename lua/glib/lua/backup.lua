local backupTable = GLib.GetSessionVariable ("GLib", "LuaBackup", {})

function GLib.Lua.GetBackup (tableName, key)
	return GLib.Lua.GetBackupTable (tableName) [key]
end

function GLib.Lua.GetBackupTable (tableName)
	backupTable [tableName] = backupTable [tableName] or {}
	return backupTable [tableName]
end

function GLib.Lua.Backup (tableName, key, value)
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	
	if value == nil then
		value = GLib.Lua.GetTable (tableName) [key]
	end
	
	backupTable [key] = backupTable [key] or value
end

function GLib.Lua.BackupTable (tableName, table)
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	
	table = table or GLib.Lua.GetTable (tableName)
	
	for k, v in pairs (table) do
		backupTable [k] = backupTable [k] or v
	end
end