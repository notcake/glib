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
	self.FrameVariableNames = {}
	self.FrameVariableStartInstructions = {}
	self.FrameVariableEndInstructions = {}
	self.FrameVariableTags = {}
	
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
	self.InstructionTags = {}
	
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
	
	-- Upvalues
	for i = 1, self.UpvalueCount do
		self.UpvalueNames [i] = debugReader:StringZ ()
		if self.UpvalueNames [i] == "" then
			self.UpvalueNames [i] = nil
		end
	end
	
	-- Frame Variables
	for i = 1, self.FrameSize do
		self.FrameVariableNames [i] = debugReader:StringZ ()
		if self.FrameVariableNames [i] == "" then
			self.FrameVariableNames [i] = nil
		end
		self.FrameVariableStartInstructions [i] = debugReader:ULEB128 ()
		self.FrameVariableEndInstructions [i] = debugReader:ULEB128 ()
	end
	
	self.DebugResidualData = debugReader:Bytes (1024)
	self.Rest = reader:Bytes (1024)
	
	self:Decompile ()
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

function self:GetInstructionEnumerator ()
	local i = 0
	local instruction = GLib.Lua.Instruction (self)
	return function ()
		i = i + 1
		
		if i > self.InstructionCount then return nil end
		
		instruction = self:GetInstruction (i, instruction)
		
		return instruction
	end
end

function self:GetInstructionTag (instructionId, tagId)
	if not self.InstructionTags [tagId] then return nil end
	return self.InstructionTags [tagId] [instructionId]
end

function self:SetInstructionTag (instructionId, tagId, data)
	self.InstructionTags [tagId] = self.InstructionTags [tagId] or {}
	self.InstructionTags [tagId] [instructionId] = data
end

-- Variables
-- Frame
function self:GetFrameSize ()
	return self.FrameSize
end

function self:GetFrameVariable (id, frameVariable)
	frameVariable = frameVariable or GLib.Lua.FrameVariable (self)
	
	frameVariable:SetIndex (id)
	
	return frameVariable
end

function self:GetFrameVariableName (id)
	return self.FrameVariableNames [id]
end

function self:GetFrameVariableStartInstruction (id)
	return self.FrameVariableStartInstructions [id]
end

function self:GetFrameVariableEndInstruction (id)
	return self.FrameVariableEndInstructions [id]
end

function self:GetFrameVariableInstructionRange (id)
	return self.FrameVariableStartInstructions [id], self.FrameVariableEndInstructions [id]
end

function self:GetFrameVariableTag (id, tagId)
	if not self.FrameVariableTags [tagId] then return nil end
	return self.FrameVariableTags [tagId] [id]
end

function self:SetFrameVariableTag (id, tagId, data)
	self.FrameVariableTags [tagId] = self.FrameVariableTags [tagId] or {}
	self.FrameVariableTags [tagId] [id] = data
end

-- Parameters
function self:GetParameter (id, frameVariable)
	return self:GetFrameVariable (id, frameVariable)
end

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
	local parameterVariable = GLib.Lua.FrameVariable (self)
	for i = 1, self:GetParameterCount () do
		if i > 1 then
			str:Append (", ")
		end
		
		parameterVariable = self:GetParameter (i, parameterVariable)
		str:Append (parameterVariable:GetNameOrFallbackName ())
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
		if lastLine and instruction:GetLine () and instruction:GetLine () - lastLine >= 2 then
			str:Append ("\t\n")
		end
		lastLine = instruction:GetLine ()
		
		-- Instruction
		str:Append ("\t")
		if instruction:GetTag ("Lua") then
			if instruction:GetTag ("Lua") ~= "" then
				str:Append (instruction:GetTag ("Lua"):gsub ("\n", "\n\t"))
				str:Append ("\n")
			end
		else
			str:Append (instruction:ToString ())
			if instruction:GetTag ("Comment") then
				str:Append ("\t// ")
				str:Append (instruction:GetTag ("Comment"))
			end
			str:Append ("\n")
		end
	end
	
	str:Append ("end")
	
	self.String = str:ToString ()
	
	return self.String
end

self.__tostring = self.ToString

-- Internal, do not call
function self:Decompile ()
	local frameVariableTags = {}
	
	local variable = GLib.Lua.FrameVariable (self)
	local aVariable = GLib.Lua.FrameVariable (self)
	local bVariable = GLib.Lua.FrameVariable (self)
	local cVariable = GLib.Lua.FrameVariable (self)
	local dVariable = GLib.Lua.FrameVariable (self)
	
	for instruction in self:GetInstructionEnumerator () do
		local destinationVariable
		local destinationVariableName
		local isAssignment = false
		local firstAssignment = false
		local assignmentExpression
		local assignmentExpressionIndexable = false
		
		aVariable = self:GetFrameVariable (instruction:GetOperandA () + 1, aVariable)
		bVariable = self:GetFrameVariable (instruction:GetOperandB () + 1, bVariable)
		cVariable = self:GetFrameVariable (instruction:GetOperandC () + 1, cVariable)
		dVariable = self:GetFrameVariable (instruction:GetOperandD () + 1, dVariable)
		
		if instruction:GetOperandAType () == GLib.Lua.OperandType.DestinationVariable then
			destinationVariable = aVariable
			destinationVariableName = aVariable:GetNameOrFallbackName ()
			
			firstAssignment = aVariable:SetAssigned (instruction:GetIndex ())
		end
		
		local opcode = instruction:GetOpcodeName ()
		
		-- Loads
		if opcode == "KSTR" then
			isAssignment = true
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = "\"" .. GLib.String.EscapeNonprintable (assignmentExpressionRawValue) .. "\""
		elseif opcode == "KSHORT" then
			isAssignment = true
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
		elseif opcode == "KNUM" then
			isAssignment = true
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
		elseif opcode == "KPRI" then
			isAssignment = true
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
		elseif opcode == "KNIL" then
			assignmentExpression = "nil"
			local lua = ""
			local first = true
			for i = instruction:GetOperandA (), instruction:GetOperandD () do
				if first then
					first = false
				else
					lua = lua .. "\n"
				end
				
				variable = self:GetFrameVariable (i + 1, variable)
				firstAssignment = variable:SetAssigned (instruction:GetIndex ())
				lua = lua .. (firstAssignment and "local " or "") .. variable:GetNameOrFallbackName () .. " = " .. assignmentExpression
				variable:SetExpression ("nil", false, nil)
			end
			instruction:SetTag ("Lua", lua)
		end
		
		-- Upvalue operations
		if opcode == "UGET" then
			isAssignment = true
			assignmentExpression = self:GetUpvalueName (instruction:GetOperandD () + 1) or ("_up" .. tostring (instruction:GetOperandD ()))
		end
		
		-- Unary operations
		if opcode == "MOV" then
			isAssignment = true
			assignmentExpression = dVariable:GetExpressionOrFallback ()
		end
		
		-- Tables
		if opcode == "GGET" then
			isAssignment = true
			assignmentExpression = instruction:GetOperandDValue ()
		elseif opcode == "GSET" then
			isAssignment = true
			destinationVariableName = instruction:GetOperandDValue ()
			assignmentExpression = aVariable:GetExpressionOrFallback ()
		elseif opcode == "TGETS" then
			isAssignment = true
			
			local cValue = instruction:GetOperandCValue ()
			if type (cValue) == "string" and GLib.Lua.IsValidVariableName (cValue) then
				assignmentExpression = bVariable:GetExpressionOrFallback () .. "." .. cValue
			else
				assignmentExpression = bVariable:GetExpressionOrFallback () .. "[\"" .. GLib.String.EscapeNonprintable (cValue) .. "\"]"
			end
		end
		
		-- Calls
		if opcode == "CALLM" then
			local returnCount = instruction:GetOperandB () - 1
			assignmentExpression = aVariable:GetExpressionOrFallback () .. " ("
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1, variable)
				
				assignmentExpression = assignmentExpression .. variable:GetExpressionOrFallback () .. ", "
			end
			assignmentExpression = assignmentExpression .. "..."
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				instruction:SetTag ("Lua", "... = " .. assignmentExpression)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					
					variable = self:GetFrameVariable (i + 1, variable)
					variable:ClearExpression ()
					firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					variable:SetExpression (assignmentExpression, true, nil)
				end
				instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
			end
		elseif opcode == "CALL" then
			local returnCount = instruction:GetOperandB () - 1
			assignmentExpression = aVariable:GetExpressionOrFallback () .. " ("
			
			-- Parameters
			local first = true
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () - 1 do
				if not first then
					assignmentExpression = assignmentExpression .. ", "
				end
				first = false
				
				variable = self:GetFrameVariable (i + 1, variable)
				
				assignmentExpression = assignmentExpression .. variable:GetExpressionOrFallback ()
			end
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				instruction:SetTag ("Lua", "... = " .. assignmentExpression)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					
					variable = self:GetFrameVariable (i + 1, variable)
					variable:ClearExpression ()
					firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					variable:SetExpression (assignmentExpression, true, nil)
				end
				instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
			end
		end
		
		-- Conditions
		if opcode == "ISGE" then
			instruction:SetTag ("Lua", "COND = " .. aVariable:GetExpressionOrFallback () .. " >= " .. dVariable:GetExpressionOrFallback ())
		end
		
		if destinationVariable then
			destinationVariable:ClearExpression ()
		end
		
		if isAssignment then
			if destinationVariable then
				destinationVariable:SetExpression (assignmentExpression, assignmentExpressionIndexable, assignmentExpressionRawValue)
			end
			instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableName .. " = " .. assignmentExpression)
		end
	end
end