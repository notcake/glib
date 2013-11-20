local self = {}
GLib.Lua.BytecodeReader = GLib.MakeConstructor (self)

function self:ctor (dump)
	self.Dump = dump
	
	local reader = GLib.StringInBuffer (self.Dump)
	reader.Int = function (self)
		local value = 0
		local factor = 1
		
		while true do
			local done = true
			local byte = self:UInt8 ()
			if byte >= 0x80 then
				done = false
				byte = byte - 0x80
			end
			value = value + byte * factor
			factor = factor * 128
			
			if done then break end
		end
		return value
	end
	
	self.Signature = reader:Bytes (4)
	self.Reserved1 = reader:UInt8 ()
	
	self.Source = reader:Bytes (reader:UInt8 ())
	self.DataLength = reader:Int ()
	
	self.VariadicFlags = reader:UInt8 ()
	self.IsVariadic = bit.band (self.VariadicFlags, 2) ~= 0
	
	self.ParameterCount = reader:UInt8 ()
	self.FrameSize = reader:UInt8 ()
	self.UpvalueCount = reader:UInt8 ()
	
	self.KGCCount = reader:Int ()
	self.KNCount = reader:Int ()
	self.BCCount = reader:Int ()
	
	self.DebugDataLength = reader:Int ()
	
	self.StartLine = reader:Int ()
	self.LineCount = reader:Int ()
	self.EndLine = self.StartLine + self.LineCount
	
	self.Instructions = {}
	for i = 1, self.BCCount do
		local instruction = {}
		self.Instructions [#self.Instructions + 1] = instruction
		
		instruction.Opcode = reader:UInt8 ()
		instruction.OpcodeName = GLib.Lua.Opcode [instruction.Opcode]
		instruction.OperandA = reader:UInt8 ()
		instruction.OperandC = reader:UInt8 ()
		instruction.OperandB = reader:UInt8 ()
		instruction.OperandD = instruction.OperandB * 256 + instruction.OperandC
	end
	
	self.UpvalueData = {}
	for i = 1, self.UpvalueCount do
		self.UpvalueData [#self.UpvalueData + 1] = reader:UInt16 ()
	end
	
	self.Constants = {}
	for i = 1, self.KGCCount do
		local constant = {}
		self.Constants [#self.Constants + 1] = constant
		
		constant.Type = reader:Int ()
	end
	
	self.Bytecode = reader:Bytes (1024)
end

function self:ToString ()
	local str = GLib.StringBuilder ()
	
	for _, instruction in ipairs (self.Instructions) do
		str:Append (instruction.OpcodeName)
		str:Append (" ")
		if GLib.Lua.OpcodeInfo [instruction.Opcode].OperandDType == "___" then
			-- A, B, C
			str:Append (tostring (instruction.OperandA) .. ", " .. tostring (instruction.OperandB) .. ", " .. tostring (instruction.OperandC))
		else
			-- A, D
			str:Append (tostring (instruction.OperandA) .. ", " .. tostring (instruction.OperandD))
		end
		str:Append ("\n")
	end
	
	return str:ToString ()
end

self.__tostring = self.ToString