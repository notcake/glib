local self = {}
GLib.Lua.FunctionCache = GLib.MakeConstructor (self)

function self:ctor ()
	self.Cache = GLib.WeakTable ()
end

function self:ContainsFunction (func)
	return self.Cache [func] ~= nil
end

function self:GetFunction (func)
	if self.Cache [func] then
		return self.Cache [func]
	end
	
	local functionInfo = GLib.Lua.Function.FromFunction (func)
	self.Cache [func] = functionInfo
	
	return functionInfo
end

GLib.Lua.FunctionCache = GLib.Lua.FunctionCache ()