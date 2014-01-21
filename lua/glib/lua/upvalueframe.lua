local self = {}
GLib.Lua.UpvalueFrame = GLib.MakeConstructor (self, GLib.Lua.VariableFrame)

function self:ctor (f)
	if type (f) == "table" then
		f = f:GetFunction ()
	end
	
	local i = 1
	while true do
		local name, value = debug.getupvalue (f, i)
		if name == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i + 1
	end
end