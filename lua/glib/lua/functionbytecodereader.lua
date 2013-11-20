local self = {}
GLib.Lua.FunctionBytecodeReader = GLib.MakeConstructor (self)

function self:ctor (bytecodeReader, functionDump)
	self.BytecodeReader = bytecodeReader
	
	-- Input
	self.Dump = functionDump
	
	-- ToString
	self.String = nil
	
	-- Variables
	-- Frame
	self.FrameSize = 0
	
	-- Parameters
	self.ParameterCount = 0
	self.VariadicFlags = 0
	self.Variadic = false
	
	-- Upvalues
	self.UpvalueCount = 0
	self.UpvalueData = {}
	self.UpvalueNames = {}
	
	-- Constants
	-- Garbage Collected Constants
	self.GarbageCollectedConstantCount = 0
	self.GarbageCollectedConstants = {}
	
	-- Numeric Constants
	self.NumericConstantCount = 0
	self.NumericConstants = {}
	
	-- Instructions
	self.InstructionCount = 0
	self.InstructionOpcodes = {}
	self.InstructionOperandAs = {}
	self.InstructionOperandBs = {}
	self.InstructionOperandCs = {}
	self.InstructionLines = {}
	
	-- Debugging
	self.StartLine = 0
	self.LineCount = 0
	self.EndLine = 0
	
	self.DebugDataLength = 0
	self.DebugData = nil
	self.ResidualDebugData = nil
	
	-- Read
	local reader = GLib.StringInBuffer (functionDump)
	
	-- Parameters
	self.VariadicFlags = reader:UInt8 ()
	self.Variadic = bit.band (self.VariadicFlags, 2) ~= 0
	
	self.ParameterCount = reader:UInt8 ()
	
	-- Variables
	self.FrameSize = reader:UInt8 ()
	self.UpvalueCount = reader:UInt8 ()
	
	-- Constant Counts
	self.GarbageCollectedConstantCount = reader:ULEB128 ()
	self.NumericConstantCount = reader:ULEB128 ()
	self.InstructionCount = reader:ULEB128 ()
	
	self.DebugDataLength = reader:ULEB128 ()
	
	self.StartLine = reader:ULEB128 ()
	self.LineCount = reader:ULEB128 ()
	self.EndLine = self.StartLine + self.LineCount
	
	-- Instructions
	for i = 1, self.InstructionCount do
		self.InstructionOpcodes [#self.InstructionOpcodes + 1] = reader:UInt8 ()
		self.InstructionOperandAs [#self.InstructionOperandAs + 1] = reader:UInt8 ()
		self.InstructionOperandCs [#self.InstructionOperandCs + 1] = reader:UInt8 ()
		self.InstructionOperandBs [#self.InstructionOperandBs + 1] = reader:UInt8 ()
	end
	
	-- Upvalues
	for i = 1, self.UpvalueCount do
		self.UpvalueData [i] = reader:UInt16 ()
	end
	
	-- Garbage collected constants
	for i = 1, self.GarbageCollectedConstantCount do
		local constant = {}
		self.GarbageCollectedConstants [i] = constant
		
		constant.Type = reader:ULEB128 ()
		if constant.Type == 0 then
			-- Child function
		elseif constant.Type == 1 then
			-- Table
			GLib.Error ("Unhandled garbage collected constant type (table)")
		elseif constant.Type == 2 then
			-- Int64
			GLib.Error ("Unhandled garbage collected constant type (int64)")
		elseif constant.Type == 3 then
			-- UInt64
			GLib.Error ("Unhandled garbage collected constant type (uint64)")
		elseif constant.Type == 4 then
			-- Complex
			GLib.Error ("Unhandled garbage collected constant type (complex)")
		elseif constant.Type >= 5 then
			local stringLength = constant.Type - 5
			constant.Type = 4
			constant.Length = stringLength
			constant.Value = reader:Bytes (constant.Length)
		end
	end
	
	-- Numeric constants
	for i = 1, self.NumericConstantCount do
		local constant = {}
		self.NumericConstants [i] = constant
		
		local low32 = reader:ULEB128 ()
		local high32 = 0
		
		if (low32 % 2) == 1 then
			high32 = reader:ULEB128 ()
			low32 = math.floor (low32 / 2)
			constant.Value = GLib.BitConverter.UInt32sToDouble (low32, high32)
		else
			low32 = math.floor (low32 / 2)
			constant.Value = low32
		end
		
		constant.High = string.format ("0x%08x", high32)
		constant.Low = string.format ("0x%08x", low32)
	end
	
	-- Debugging data
	self.DebugData = reader:Bytes (self.DebugDataLength)
	
	local debugReader = GLib.StringInBuffer (self.DebugData)
	if self.LineCount < 256 then
		for i = 1, self.InstructionCount do
			self.InstructionLines [i] = debugReader:UInt8 ()
		end
	elseif self.LineCount < 65536 then
		for i = 1, self.InstructionCount do
			self.InstructionLines [i] = debugReader:UInt16 ()
		end
	else
		for i = 1, self.InstructionCount do
			self.InstructionLines [i] = debugReader:UInt32 ()
		end
	end
	
	for i = 1, self.UpvalueCount do
		self.UpvalueNames [i] = debugReader:StringZ ()
	end
	
	self.DebugResidualData = debugReader:Bytes (1024)
	
	self.Rest = reader:Bytes (1024)
end

function self:GetBytecodeReader ()
	return self.BytecodeReader
end

-- Constants
-- Garbage Collected Constants
function self:GetGarbageCollectedConstantCount ()
	return self.GarbageCollectedConstantCount
end

function self:GetGarbageCollectedConstantValue (constantId)
	local constant = self.GarbageCollectedConstants [constantId]
	if not constant then return nil end
	return constant.Value
end

-- Numeric Constants
function self:GetNumericConstantCount ()
	return self.NumericConstantCount
end

function self:GetNumericConstantValue (constantId)
	local constant = self.NumericConstants [constantId]
	if not constant then return nil end
	return constant.Value
end

-- Instructions
function self:GetInstruction (instructionId, instruction)
	instruction = instruction or GLib.Lua.Instruction (self)
	
	instruction:SetIndex (instructionId)
	instruction:SetOpcode (self.InstructionOpcodes [instructionId])
	instruction:SetOperandA (self.InstructionOperandAs [instructionId])
	instruction:SetOperandB (self.InstructionOperandBs [instructionId])
	instruction:SetOperandC (self.InstructionOperandCs [instructionId])
	instruction:SetLine (self.InstructionLines [instructionId])
	
	return instruction
end

function self:GetInstructionCount ()
	return self.InstructionCount
end

function self:GetInstructionCount ()
	return #self.Instructions
end

-- Variables
-- Frame
function self:GetFrameSize ()
	return self.FrameSize
end

function self:GetFrameVariableName (id)
	
end

-- Parameters
function self:GetParameterCount ()
	return self.ParameterCount
end

function self:GetParameterName (id)
	return self:GetFrameVariableName (id)
end

function self:IsVariadic ()
	return self.Variadic
end

-- Upvalues
function self:GetUpvalueCount ()
	return self.UpvalueCount
end

function self:GetUpvalueName (upvalueId)
	return self.UpvalueNames [upvalueId]
end

function self:ToString ()
	if self.String then return self.String end
	
	local str = GLib.StringBuilder ()
	
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
	
	
	local instruction = GLib.Lua.Instruction (self)
	
	local lastLine = 0
	for i = 1, self.InstructionCount do
		instruction = self:GetInstruction (i, instruction)
		
		-- Newlines
		if instruction:GetLine () and instruction:GetLine () - lastLine >= 2 then
			str:Append ("\n")
		end
		lastLine = instruction:GetLine ()
		
		-- Instruction
		str:Append ("\t")
		str:Append (instruction:ToString ())
		str:Append ("\n")
	end
	
	str:Append ("end")
	
	self.String = str:ToString ()
	
	return self.String
end

self.__tostring = self.ToString