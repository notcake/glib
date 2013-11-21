local self = {}
GLib.Lua.LoadStore = GLib.MakeConstructor (self)

function self:ctor (frameVariable)
	self.FrameVariable = frameVariable
	
	self.Index = 0
end

function self:Clone (loadStore)
	loadStore = loadStore or GLib.Lua.LoadStore (self.FrameVariable)
	loadStore.FrameVariable = self.FrameVariable
	loadStore.Index = self.Index
	
	return loadStore
end

function self:GetExpression ()
	return self.FrameVariable.LoadStoreExpressions [self.Index]
end

function self:GetExpressionRawValue ()
	return self.FrameVariable.LoadStoreExpressionRawValues [self.Index]
end

function self:GetFrameVariable ()
	return self.FrameVariable
end

function self:GetIndex ()
	return self.Index
end

function self:GetInstruction (instruction)
	return self.FrameVariable:GetFunctionBytecodeReader ():GetInstruction (self:GetInstructionId ())
end

function self:GetInstructionId ()
	return self.FrameVariable.LoadStoreInstructions [self.Index]
end

function self:GetLoadCount ()
	return self.FrameVariable.LoadStoreLoadCounts [self.Index] or 0
end

function self:GetNext (loadStore)
	return self.FrameVariable:GetLoadStore (self.Index + 1, loadStore or self)
end

function self:GetNextLoad (loadStore)
	local index = self.Index + 1
	while self.FrameVariable.LoadStoreTypes [index] and self.FrameVariable.LoadStoreTypes [index] ~= "Load" do
		index = index + 1
	end
	return self.FrameVariable:GetLoadStore (index, loadStore or self)
end

function self:GetNextStore (loadStore)
	local index = self.Index + 1
	while self.FrameVariable.LoadStoreTypes [index] and self.FrameVariable.LoadStoreTypes [index] ~= "Store" do
		index = index + 1
	end
	return self.FrameVariable:GetLoadStore (index, loadStore or self)
end

function self:GetPrevious (loadStore)
	return self.FrameVariable:GetLoadStore (self.Index - 1, loadStore or self)
end

function self:IsExpressionInlineable ()
	return self.FrameVariable.LoadStoreExpressionInlineables [self.Index] or false
end

function self:IsLoad ()
	return self.FrameVariable.LoadStoreTypes [self.Index] == "Load"
end

function self:IsStore ()
	return self.FrameVariable.LoadStoreTypes [self.Index] == "Store"
end

function self:SetExpression (expression)
	self.FrameVariable.LoadStoreExpressions [self.Index] = expression
end

function self:SetExpressionRawValue (expressionRawValue)
	self.FrameVariable.LoadStoreExpressionRawValues [self.Index] = expressionRawValue
end

function self:SetExpressionInlineable (expressionInlineable)
	self.FrameVariable.LoadStoreExpressionInlineables [self.Index] = expressionInlineable
end

function self:SetFrameVariable (frameVariable)
	self.FrameVariable = frameVariable
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetInstructionId (instructionId)
	self.FrameVariable.LoadStoreInstructions [self.Index] = instructionId
end

function self:SetLoadCount (loadCount)
	self.FrameVariable.LoadStoreLoadCounts [self.Index] = loadCount
end

function self:ToString ()
	local loadStore = self:IsLoad () and "Load" or "Store"
	loadStore = loadStore .. self:GetIndex ()
	loadStore = loadStore .. " "
	loadStore = loadStore .. self.FrameVariable:GetNameOrFallbackName ()
	
	local instruction = self:GetInstruction ()
	if instruction then
		loadStore = loadStore .. "\t" .. instruction:ToString ()
	end
	return loadStore
end

self.__tostring = self.ToString