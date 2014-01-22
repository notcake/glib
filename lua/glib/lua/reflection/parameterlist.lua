local self = {}
GLib.Lua.ParameterList = GLib.MakeConstructor (self)

function self:ctor (f)
	self.Function = f
	
	self.Parameters = {}
	
	self.VariadicValid = true
	self.Variadic = false
	
	if type (f) == "table" then
		f = f:GetFunction ()
	end
end

function self:AddParameter (name)
	local parameter = GLib.Lua.Parameter (self, name)
	parameter:SetFrameIndex (#self.Parameters)
	
	self.Parameters [#self.Parameters + 1] = parameter
	
	return parameter
end

function self:AddVariadicParameter ()
	local parameter = self:AddParameter ()
	parameter:SetVariadic (true)
	return parameter
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Parameters [i]
	end
end

function self:IsVariadic ()
	
end

function self:ToString ()
	local parameterList = "("
	
	for parameter in self:GetEnumerator () do
	end
	
	parameterList = parameterList .. ")"
end