local self = {}
GLib.Lua.LocalVariableFrame = GLib.MakeConstructor (self, GLib.Lua.VariableFrame)

function self:ctor (offset)
	offset = offset or 0
	offset = 4 + offset
	
	local i = 1
	while true do
		local name, value = debug.getlocal (offset, i)
		if name == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i + 1
	end
	
	-- Variadic arguments
	i = -1
	while true do
		local name, value = debug.getlocal (offset, i)
		if name == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i - 1
	end
end