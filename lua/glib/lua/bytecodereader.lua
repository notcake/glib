local self = {}
GLib.Lua.BytecodeReader = GLib.MakeConstructor (self)

function self:ctor (functionOrDump)
	self.Function = nil
	self.Dump = nil

	if type (functionOrDump) == "string" then
		self.Dump = functionOrDump
	else
		self.Function = functionOrDump
		self.Dump = string.dump (self.Function)
	end
	
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
	self.Variadic = bit.band (self.VariadicFlags, 2) ~= 0
	
	self.ParameterCount = reader:UInt8 ()
	self.FrameSize = reader:UInt8 ()
	self.UpvalueCount = reader:UInt8 ()
	
	self.GarbageCollectedConstantCount = reader:Int ()
	self.NumericConstantCount = reader:Int ()
	self.InstructionCount = reader:Int ()
	
	self.DebugDataLength = reader:Int ()
	
	self.StartLine = reader:Int ()
	self.LineCount = reader:Int ()
	self.EndLine = self.StartLine + self.LineCount
	
	self.InstructionOpcodes = {}
	self.InstructionOperandAs = {}
	self.InstructionOperandBs = {}
	self.InstructionOperandCs = {}
	for i = 1, self.InstructionCount do
		self.InstructionOpcodes [#self.InstructionOpcodes + 1] = reader:UInt8 ()
		self.InstructionOperandAs [#self.InstructionOperandAs + 1] = reader:UInt8 ()
		self.InstructionOperandCs [#self.InstructionOperandCs + 1] = reader:UInt8 ()
		self.InstructionOperandBs [#self.InstructionOperandBs + 1] = reader:UInt8 ()
	end
	
	self.UpvalueData = {}
	for i = 1, self.UpvalueCount do
		self.UpvalueData [i - 1] = reader:UInt16 ()
	end
	
	self.GarbageCollectedConstants = {}
	for i = 1, self.GarbageCollectedConstantCount do
		local constant = {}
		self.GarbageCollectedConstants [i] = constant
		
		constant.Type = reader:Int ()
		if constant.Type >= 4 then
			local stringLength = constant.Type - 4
			constant.Type = 4
			constant.Length = stringLength - 1
			constant.Value = reader:Bytes (constant.Length)
		end
	end
	
	self.NumericConstants = {}
	for i = 1, self.NumericConstantCount do
		local constant = {}
		self.NumericConstants [i] = constant
		
		local low32 = reader:Int ()
		local high32 = 0
		
		if (low32 % 2) == 1 then
			high32 = reader:Int ()
			low32 = math.floor (low32 / 2)
			constant.Value = GLib.BitConverter.UInt32sToDouble (low32, high32)
		else
			low32 = math.floor (low32 / 2)
			constant.Value = low32
		end
		
		constant.High = string.format ("0x%08x", high32)
		constant.Low = string.format ("0x%08x", low32)
	end
	
	self.DebugData = reader:Bytes (self.DebugDataLength)
	
	self.Rest = reader:Bytes (1024)
end

function self:GetGarbageCollectedConstantCount ()
	return self.GarbageCollectedConstantCount
end

function self:GetGarbageCollectedConstantValue (constantId)
	local constant = self.GarbageCollectedConstants [constantId]
	if not constant then return nil end
	return constant.Value
end

function self:GetFunction ()
	return self.Function
end

function self:GetInstruction (instructionId, instruction)
	instruction = instruction or GLib.Lua.Instruction (self)
	
	local instructionTable = self.Instructions [instructionId]
	instruction:SetOpcode (instructionTable.Opcode)
	instruction:SetOperandA (instructionTable.OperandA)
	instruction:SetOperandB (instructionTable.OperandB)
	instruction:SetOperandC (instructionTable.OperandC)
	
	return instruction
end

function self:GetInstructionCount ()
	return self.InstructionCount
end

function self:GetInstructionCount ()
	return #self.Instructions
end

function self:GetNumericConstantCount ()
	return self.NumericConstantCount
end

function self:GetNumericConstantValue (constantId)
	local constant = self.NumericConstants [constantId]
	if not constant then return nil end
	return constant.Value
end

function self:GetParameterCount ()
	return self.ParameterCount
end

function self:IsVariadic ()
	return self.Variadic
end

function self:ToString ()
	local str = GLib.StringBuilder ()
	
	local instruction = GLib.Lua.Instruction (self)
	
	str:Append ("function (")
	for i = 1, self:GetParameterCount () do
		if i > 1 then
			str:Append (", ")
		end
		str:Append ("_" .. tostring (i))
	end
	
	if self:IsVariadic () then
		if self:GetParameterCount () > 0 then
			str:Append (", ")
		end
		str:Append ("...")
	end
	
	str:Append (")\n")
	
	for i = 1, self.InstructionCount do
		instruction:SetIndex (i)
		instruction:SetOpcode (self.InstructionOpcodes [i])
		instruction:SetOperandA (self.InstructionOperandAs [i])
		instruction:SetOperandB (self.InstructionOperandBs [i])
		instruction:SetOperandC (self.InstructionOperandCs [i])
		
		str:Append ("\t")
		str:Append (instruction:ToString ())
		str:Append ("\n")
	end
	
	str:Append ("end")
	
	return str:ToString ()
end

self.__tostring = self.ToString