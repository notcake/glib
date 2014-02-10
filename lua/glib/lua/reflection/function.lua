local self = {}
GLib.Lua.Function = GLib.MakeConstructor (self)

function GLib.Lua.Function.ctor (func)
	return GLib.Lua.FunctionCache:GetFunction (func)
end

function GLib.Lua.Function.FromFunction (func)
	return GLib.Lua.Function.__ictor (func)
end

function self:ctor (func)
	self.Function = func
	self.InfoTable = debug.getinfo (func)
	
	self.ParameterList = nil
end

function self:GetFunction ()
	return self.Function
end

function self:GetPrototype ()
	return "function " .. self:GetParameterList ():ToString ()
end

function self:GetInfoTable ()
	return self.InfoTable
end

function self:GetParameterList ()
	if self.ParameterList == nil then
		self.ParameterList = GLib.Lua.ParameterList (self)
	end
	
	return self.ParameterList
end

function self:IsNative ()
	return self.InfoTable.what == "C"
end

function self:ToString ()
	return "function " .. self:GetParameterList ():ToString ()
end