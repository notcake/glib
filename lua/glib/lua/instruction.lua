local self = {}
GLib.Lua.Instruction = GLib.MakeConstructor (self)

function self:ctor (bytecodeReader)
	self.BytecodeReader = bytecodeReader
	self.Index = 1
	
	self.Opcode = nil
	self.OpcodeName = nil
	self.OpcodeInfo = nil
	
	self.OperandA = 0
	self.OperandB = 0
	self.OperandC = 0
	self.OperandD = 0
end

function self:GetIndex ()
	return self.Index
end

function self:GetOperandA ()
	return self.OperandA
end

function self:GetOperandAType ()
	return self.OpcodeInfo:GetOperandAType ()
end

function self:GetOperandB ()
	return self.OperandB
end

function self:GetOperandBType ()
	return self.OpcodeInfo:GetOperandBType ()
end

function self:GetOperandC ()
	return self.OperandC
end

function self:GetOperandCType ()
	return self.OpcodeInfo:GetOperandCType ()
end

function self:GetOperandD ()
	return self.OperandD
end

function self:GetOperandDType ()
	return self.OpcodeInfo:GetOperandDType ()
end

function self:GetOpcode ()
	return self.Opcode
end

function self:GetOpcodeInfo ()
	return self.OpcodeInfo
end

function self:GetOpcodeName ()
	return self.OpcodeName
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetOperandA (operandA)
	self.OperandA = operandA
end

function self:SetOperandB (operandB)
	self.OperandB = operandB
	
	self.OperandD = self.OperandB * 256 + self.OperandC
end

function self:SetOperandC (operandC)
	self.OperandC = operandC
	
	self.OperandD = self.OperandB * 256 + self.OperandC
end

function self:SetOperandD (operandD)
	self.OperandD = operandD
	
	self.OperandB = math.floor (self.OperandD / 256)
	self.OperandC = self.OperandD % 256
end

function self:SetOpcode (opcode)
	self.Opcode = opcode
	self.OpcodeName = GLib.Lua.Opcode [self.Opcode]
	self.OpcodeInfo = GLib.Lua.Opcodes:GetOpcode (self.Opcode)
end

function self:ToString ()
	local instruction = self.OpcodeName .. " "
	
	local operandA = self:FormatOperand (self.OperandA, self:GetOperandAType ())
	
	if self:GetOperandDType () == GLib.Lua.OperandType.None then
		-- A, B, C
		local operandB = self:FormatOperand (self.OperandB, self:GetOperandBType ())
		local operandC = self:FormatOperand (self.OperandC, self:GetOperandCType ())
		
		instruction = instruction .. operandA .. ", " .. operandB .. ", " .. operandC
	else
		-- A, D
		local operandD = self:FormatOperand (self.OperandD, self:GetOperandDType ())
		
		instruction = instruction .. operandA .. ", " .. operandD
	end
	
	return instruction
end

self.__tostring = self.ToString

-- Internal, do not call
function self:FormatOperand (operand, operandType)
	if operandType == GLib.Lua.OperandType.Variable then
		return "_" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.DestinationVariable then
		return "_" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.Literal then
		return tostring (operand)
	elseif operandType == GLib.Lua.OperandType.SignedLiteral then
		if operand < 32768 then
			return tostring (operand)
		else
			return tostring (operand - 65536)
		end
	elseif operandType == GLib.Lua.OperandType.Primitive then
		if operand == 0 then return "nil"
		elseif operand == 1 then return "false"
		elseif operand == 2 then return "true" end
		return "pri" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.NumericConstantId then
		local constantValue = self.BytecodeReader:GetNumericConstantValue (operand + 1)
		if constantValue then
			return constantValue
		else
			return "num" .. tostring (operand)
		end
	elseif operandType == GLib.Lua.OperandType.StringConstantId then
		local constantValue = self.BytecodeReader:GetGarbageCollectedConstantValue (self.BytecodeReader:GetGarbageCollectedConstantCount () - operand)
		if constantValue then
			return "\"" .. GLib.String.EscapeNonprintable (constantValue) .. "\""
		else
			return "str-" .. tostring (operand)
		end
	elseif operandType == GLib.Lua.OperandType.RelativeJump then
		return tostring (operand - 0x8000)
	else
		return GLib.Lua.OperandType [operandType] .. " " .. tostring (operand)
	end
	
	return tostring (operand)
end