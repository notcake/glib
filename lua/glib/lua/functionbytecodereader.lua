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
	self.FrameVariables = {}
	self.VariadicFrameVariable = GLib.Lua.FrameVariable (self, "...")
	self.VariadicFrameVariable:SetName ("...")
	
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
		local frameVariable = GLib.Lua.FrameVariable (self, i)
		self.FrameVariables [i] = frameVariable
		frameVariable:SetName (debugReader:StringZ ())
		frameVariable:SetStartInstruction (debugReader:ULEB128 ())
		frameVariable:SetEndInstruction (debugReader:ULEB128 ())
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

function self:GetFrameVariable (id)
	if id == "..." then
		return self.VariadicFrameVariable
	end
	return self.FrameVariables [id]
end

function self:GetFrameVariableEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.FrameVariables [i]
	end
end

function self:GetFrameVariableName (id)
	local frameVariable = self:GetFrameVariable (id)
	if not frameVariable then return nil end
	return frameVariable:GetName ()
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
		if instruction:GetTag ("Lua") then
			if instruction:GetTag ("Lua") ~= "" then
				str:Append ("\t")
				str:Append (instruction:GetTag ("Lua"):gsub ("\n", "\n\t"))
				if instruction:GetTag ("Comment") then
					str:Append ("\t// ")
					str:Append (instruction:GetTag ("Comment"))
				end
				str:Append ("\n")
			else
				-- Debugging
				-- str:Append ("\t\t\t")
				-- str:Append (instruction:ToString ())
				-- if instruction:GetTag ("Comment") then
				-- 	str:Append ("\t// ")
				-- 	str:Append (instruction:GetTag ("Comment"))
				-- end
				-- str:Append ("\n")
			end
		else
			str:Append ("\t")
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
	self:DecompilePass1 ()
	self:AnalyseJumps ()
	self:DecompilePass2 ()
	self:DecompilePass3 ()
end

function self:DecompilePass1 ()
	local variable
	local destinationVariable
	local assignmentExpression
	local assignmentExpressionPrecedence
	local assignmentExpressionRawValue
	
	for instruction in self:GetInstructionEnumerator () do
		local opcodeName = instruction:GetOpcodeName ()
		assignmentExpression = nil
		assignmentExpressionPrecedence = GLib.Lua.Precedence.Lowest
		assignmentExpressionRawValue = nil
		destinationVariable = nil
		
		if instruction:GetOperandAType () == GLib.Lua.OperandType.DestinationVariable then
			destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
		end
		
		-- Constant loads
		if opcodeName == "KSTR" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = "\"" .. GLib.String.EscapeNonprintable (assignmentExpressionRawValue) .. "\""
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KSHORT" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KNUM" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KPRI" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KNIL" then
			for i = instruction:GetOperandA (), instruction:GetOperandD () do
				destinationVariable = self:GetFrameVariable (i + 1)
				destinationVariable:AddStore (instruction:GetIndex (), "nil", GLib.Lua.Precedence.Atom, nil)
			end
			
			destinationVariable = nil -- Don't add another store at the end of the loop
		end
		
		-- Upvalue operations
		if opcodeName == "UGET" then
			assignmentExpression = self:GetUpvalueName (instruction:GetOperandD () + 1) or ("_up" .. tostring (instruction:GetOperandD ()))
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		end
		
		-- Tables
		if opcodeName == "GGET" then
			assignmentExpression = instruction:GetOperandDValue ()
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		end
		
		-- Calls
		if opcodeName == "CALLM" then
			-- Function
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
			self.VariadicFrameVariable:AddLoad (instruction:GetIndex ())
			
			-- Return values
			local returnCount = instruction:GetOperandB () - 1
			if returnCount > 0 then
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					destinationVariable = self:GetFrameVariable (i + 1)
					destinationVariable:AddStore (instruction:GetIndex ())
				end
				destinationVariable = nil
			elseif returnCount == -1 then
				self.VariadicFrameVariable:AddStore (instruction:GetIndex ())
			end
		elseif opcodeName == "CALL" then
			-- Function
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () - 1 do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
			
			-- Return values
			local returnCount = instruction:GetOperandB () - 1
			if returnCount > 0 then
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					destinationVariable = self:GetFrameVariable (i + 1)
					destinationVariable:AddStore (instruction:GetIndex ())
				end
				destinationVariable = nil
			elseif returnCount == -1 then
				self.VariadicFrameVariable:AddStore (instruction:GetIndex ())
			end
		end
		
		-- Binary operators
		if opcodeName == "CAT" then
			for i = instruction:GetOperandB (), instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
		end
		
		-- Generic loads
		if instruction:GetOperandBType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandB () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		if instruction:GetOperandCType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandC () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		if instruction:GetOperandDType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandD () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		
		if destinationVariable then
			local storeId = destinationVariable:AddStore (instruction:GetIndex (), assignmentExpression, assignmentExpressionPrecedence, assignmentExpressionRawValue)
			instruction:SetStoreVariable (destinationVariable)
			instruction:SetStoreId (storeId)
		end
	end
end

function self:AnalyseJumps ()
	for instruction in self:GetInstructionEnumerator () do
	end
end

function self:DecompilePass2 ()
	for frameVariable in self:GetFrameVariableEnumerator () do
		self:AnalyseFrameVariableUsage (frameVariable)
	end
	self:AnalyseFrameVariableUsage (self.VariadicFrameVariable)
end

function self:AnalyseFrameVariableUsage (frameVariable)
	local loadStore = GLib.Lua.LoadStore (frameVariable)
	local store = nil
	
	loadStore = loadStore:GetNext ()
	
	local loadCount = 0
	while loadStore do
		if loadStore:IsStore () then
			-- Commit last store data
			if store then
				store:SetLoadCount (loadCount)
				if loadCount == 1 then
					store:SetExpressionInlineable (true)
				end
			end
			
			-- Reset data for new store
			store = loadStore:Clone (store or GLib.Lua.LoadStore (frameVariable))
			loadCount = 0
		else
			loadCount = loadCount + 1
			if store then
				loadStore:SetLastStore (store:GetIndex ())
			end
		end
		
		loadStore = loadStore:GetNext ()
	end
	
	-- Commit last store data
	if store then
		store:SetLoadCount (loadCount)
		if loadCount == 1 then
			store:SetExpressionInlineable (true)
		end
	end
end

local function GetNextLoad (loadCache, frameVariable, instructionId)
	local frameVariableId = frameVariable:GetIndex ()
	local loadStore = loadCache [frameVariableId]
	loadStore = loadStore or GLib.Lua.LoadStore (frameVariable)
	loadCache [loadStore] = loadStore
	
	loadStore = loadStore:GetNextLoad ()
	while loadStore do
		loadCache [frameVariableId] = loadStore
		if loadStore:GetInstructionId () == instructionId then
			return loadStore
		end
		
		loadStore = loadStore:GetNextLoad ()
	end
	
	return nil
end

local function GetNextStore (storeCache, frameVariable, instructionId)
	local frameVariableId = frameVariable:GetIndex ()
	local loadStore = storeCache [frameVariableId]
	loadStore = loadStore or GLib.Lua.LoadStore (frameVariable)
	storeCache [loadStore] = loadStore
	
	loadStore = loadStore:GetNextStore ()
	while loadStore do
		storeCache [frameVariableId] = loadStore
		if loadStore:GetInstructionId () == instructionId then
			return loadStore
		end
		
		loadStore = loadStore:GetNextStore ()
	end
	
	return nil
end

function self:DecompilePass3 ()
	local loadCache = {}
	local storeCache = {}
	
	local variable
	local aVariable
	local bVariable
	local cVariable
	local dVariable
	
	local loadStore = GLib.Lua.LoadStore ()
	
	for instruction in self:GetInstructionEnumerator () do
		local destinationVariable
		local destinationVariableName
		local isAssignment = false
		local firstAssignment = false
		local assignmentExpression
		local assignmentExpressionPrecedence
		local assignmentExpressionIndexable = false
		local assignmentInlineable = false
		local load = nil
		local store = nil
		
		aVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
		bVariable = self:GetFrameVariable (instruction:GetOperandB () + 1)
		cVariable = self:GetFrameVariable (instruction:GetOperandC () + 1)
		dVariable = self:GetFrameVariable (instruction:GetOperandD () + 1)
		
		if instruction:GetOperandAType () == GLib.Lua.OperandType.DestinationVariable then
			destinationVariable = aVariable
			
			-- Set store LoadStore
			store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
			assignmentExpressionRawValue = store:GetExpressionRawValue ()
			assignmentExpression = store:GetExpression ()
		end
		
		local opcode = instruction:GetOpcodeName ()
		
		-- Loads
		if opcode == "KSTR" or
		   opcode == "KSHORT" or
		   opcode == "KNUM" or
		   opcode == "KPRI" then
			isAssignment = true
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
				
				variable = self:GetFrameVariable (i + 1)
				firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
				lua = lua .. (firstAssignment and "local " or "") .. variable:GetNameOrFallbackName () .. " = " .. assignmentExpression
				variable:SetExpression ("nil", false, nil)
			end
			instruction:SetTag ("Lua", lua)
		end
		
		-- Upvalue operations
		if opcode == "UGET" then
			isAssignment = true
		end
		
		-- Unary operations
		if opcode == "MOV" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			assignmentExpression, assignmentExpressionPrecedence = load:GetExpression ()
			store:SetExpression (assignmentExpression, assignmentExpressionPrecedence)
		end
		
		-- Tables
		if opcode == "GGET" then
			isAssignment = true
		elseif opcode == "GSET" then
			isAssignment = true
			destinationVariableName = instruction:GetOperandDValue ()
			assignmentExpression = aVariable:GetExpressionOrFallback ()
		elseif opcode == "TGETS" then
			isAssignment = true
			
			-- varA = varB [strC]
			local bExpression = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			bExpression = bExpression:GetExpression ()
			
			local cValue = instruction:GetOperandCValue ()
			if type (cValue) == "string" and GLib.Lua.IsValidVariableName (cValue) then
				assignmentExpression = bExpression .. "." .. cValue
			else
				assignmentExpression = bExpression .. " [\"" .. GLib.String.EscapeNonprintable (cValue) .. "\"]"
			end
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
		elseif opcode == "TGETB" then
			isAssignment = true
			
			-- varA = varB [numC]
			local bExpression = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			bExpression = bExpression:GetExpression ()
			
			assignmentExpression = bExpression .. " [" .. tostring (instruction:GetOperandCValue ()) .. "]"
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
		end
		
		-- Calls
		if opcode == "CALLM" then
			local returnCount = instruction:GetOperandB () - 1
			assignmentExpression = aVariable:GetExpressionOrFallback () .. " ("
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetExpression () .. ", "
			end
			variable = self.VariadicFrameVariable
			load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
			assignmentExpression = assignmentExpression .. load:GetExpression ()
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				isAssignment = true
				
				-- Set store LoadStore
				destinationVariable = self.VariadicFrameVariable
				store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
				store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
				
				instruction:SetTag ("Lua", "... = " .. assignmentExpression)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					
					variable = self:GetFrameVariable (i + 1)
					firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					isAssignment = true
					
					-- Set store LoadStore
					destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
					store = GetNextStore (storeCache, variable, instruction:GetIndex ())
					store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
				else
					instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
				end
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
				
				variable = self:GetFrameVariable (i + 1)
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetExpression ()
			end
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				isAssignment = true
				
				-- Set store LoadStore
				destinationVariable = self.VariadicFrameVariable
				store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
				store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					
					variable = self:GetFrameVariable (i + 1)
					firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					isAssignment = true
					
					-- Set store LoadStore
					destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
					store = GetNextStore (storeCache, variable, instruction:GetIndex ())
					store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
				else
					instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
				end
			end
		end
		
		-- Comparison operators
		if opcode == "ISLT" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " >= " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISGE" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " < " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISLE" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " > " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISGT" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " <= " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISEQV" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " ~= " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISNEV" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " == " .. dVariable:GetExpressionOrFallback () .. " then")
		elseif opcode == "ISEQS" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " ~= " .. "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandDValue ()) .. "\"" .. " then")
		elseif opcode == "ISNES" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " == " .. "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandDValue ()) .. "\"" .. " then")
		elseif opcode == "ISEQN" or
		       opcode == "ISEQP" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " ~= " .. tostring (GLib.String.EscapeNonprintable (instruction:GetOperandDValue ())) .. " then")
		elseif opcode == "ISNEN" or
		       opcode == "ISNEP" then
			instruction:SetTag ("Lua", "if " .. aVariable:GetExpressionOrFallback () .. " == " .. tostring (GLib.String.EscapeNonprintable (instruction:GetOperandDValue ())) .. " then")
		end
		
		-- Unary testing operators
		if opcode == "IST" then
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			instruction:SetTag ("Lua", "if not " .. load:GetExpression () .. " then")
		elseif opcode == "ISF" then
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			instruction:SetTag ("Lua", "if " .. load:GetExpression () .. " then")
		end
		
		-- Binary operators
		if opcode == "DIVVN" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			assignmentExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Division) .. " / " .. tostring (instruction:GetOperandCValue ())
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Division)
		elseif opcode == "MODVN" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			assignmentExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Modulo) .. " % " .. tostring (instruction:GetOperandCValue ())
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Modulo)
		elseif opcode == "ADDNV" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			assignmentExpression = tostring (instruction:GetOperandCValue ()) .. " + " .. load:GetBracketedExpression (GLib.Lua.Precedence.Addition)
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Addition)
		elseif opcode == "ADDVV" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			local bExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Addition)
			
			load = GetNextLoad (loadCache, cVariable, instruction:GetIndex ())
			local cExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Addition)
			
			assignmentExpression = bExpression .. " + " .. cExpression
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Addition)
		elseif opcode == "MULVV" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			local bExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Multiplication)
			
			load = GetNextLoad (loadCache, cVariable, instruction:GetIndex ())
			local cExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Multiplication)
			
			assignmentExpression = bExpression .. " * " .. cExpression
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Multiplication)
		elseif opcode == "CAT" then
			isAssignment = true
			
			local first = true
			assignmentExpression = ""
			for i = instruction:GetOperandB (), instruction:GetOperandC () do
				if not first then
					assignmentExpression = assignmentExpression .. " .. "
				end
				first = false
				
				variable = self:GetFrameVariable (i + 1)
				
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetBracketedExpression (GLib.Lua.Precedence.Lowest)
			end
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Lowest)
		end
		
		if destinationVariable then
			destinationVariable:ClearExpression ()
		end
		
		if isAssignment then
			if destinationVariable then
				destinationVariableName = destinationVariable:GetNameOrFallbackName ()
				
				firstAssignment = firstAssignment or destinationVariable:SetAssigned (instruction:GetIndex ())
				destinationVariable:SetExpression (assignmentExpression, assignmentExpressionIndexable, assignmentExpressionRawValue)
			end
			store = store or instruction:GetStore (store)
			if store and store:IsExpressionInlineable () then
				instruction:SetTag ("Lua", "")
			else
				instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableName .. " = " .. assignmentExpression)
			end
		end
	end
end