local self = {}
GLib.Lua.Parameter = GLib.MakeConstructor (self)

function self:ctor (parameterList)
	self.ParameterList = parameterList
end