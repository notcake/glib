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
		end
		
		low32 = math.floor (low32 / 2)
		constant.High = string.format ("0x%08x", high32)
		constant.Low = string.format ("0x%08x", low32)
		constant.Value = low32 + high32 * 4294967296
	end
	
	self.Bytecode = reader:Bytes (1024)
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
	return #self.Instructions
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
	
	for _, instructionTable in ipairs (self.Instructions) do
		instruction:SetOpcode (instructionTable.Opcode)
		instruction:SetOperandA (instructionTable.OperandA)
		instruction:SetOperandB (instructionTable.OperandB)
		instruction:SetOperandC (instructionTable.OperandC)
		
		str:Append ("\t")
		str:Append (instruction:ToString ())
		str:Append ("\n")
	end
	
	str:Append ("end")
	
	return str:ToString ()
end

self.__tostring = self.ToString