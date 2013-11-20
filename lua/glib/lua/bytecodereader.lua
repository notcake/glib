local self = {}
GLib.Lua.BytecodeReader = GLib.MakeConstructor (self)

function self:ctor (functionOrDump)
	-- Input
	self.Function = nil
	self.Dump = nil
	
	-- Function dumps
	self.Functions = {}
	
	-- String
	self.String = nil

	if type (functionOrDump) == "string" then
		self.Dump = functionOrDump
	else
		self.Function = functionOrDump
		self.Dump = string.dump (self.Function)
	end
	
	-- Read
	local reader = GLib.StringInBuffer (self.Dump)
	
	-- Header
	self.Signature = reader:Bytes (4)
	self.Reserved1 = reader:UInt8 ()
	
	self.Source = reader:Bytes (reader:UInt8 ())
	
	-- Functions
	local functionDataLength = reader:ULEB128 ()
	while functionDataLength ~= 0 do
		local functionData = reader:Bytes (functionDataLength)
		self.Functions [#self.Functions + 1] = GLib.Lua.FunctionBytecodeReader (self, functionData)
		
		functionDataLength = reader:ULEB128 ()
	end
end

function self:GetInputFunction ()
	return self.Function
end

function self:GetFunction (index)
	return self.Functions [index]
end

function self:GetFunctionCount ()
	return #self.Functions
end

function self:GetFunctionEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Functions [i]
	end
end

function self:GetSource ()
	return self.Source
end

function self:ToString ()
	if not self.String then
		local str = GLib.StringBuilder ()
		str:Append (self:GetSource ())
		str:Append ("\n")
		str:Append ("{")
		str:Append ("\n")
		
		for functionBytecodeReader in self:GetFunctionEnumerator () do
			str:Append ("\t")
			str:Append (functionBytecodeReader:ToString ():gsub ("\n", "\n\t"))
			str:Append ("\n")
		end
		
		str:Append ("}")
		self.String = str:ToString ()
	end
	
	return self.String
end

self.__tostring = self.ToString