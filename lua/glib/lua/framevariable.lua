local self = {}
GLib.Lua.FrameVariable = GLib.MakeConstructor (self)

function self:ctor (functionBytecodeReader, index)
	self.FunctionBytecodeReader = functionBytecodeReader
	
	self.Tags = {}
	self.LoadStores = {}
	
	self.Index = index
end

function self:ClearExpression ()
	self:SetTag ("Expression", nil)
	self:SetTag ("ExpressionIndexable", nil)
	self:SetTag ("ExpressionRawValue", nil)
end

function self:GetExpressionOrFallback ()
	return self:GetTag ("Expression") or self:GetNameOrFallbackName ()
end

function self:GetExpressionRawValue ()
	return self:GetTag ("ExpressionRawValue")
end

function self:GetIndex ()
	return self.Index
end

function self:GetName ()
	return self.FunctionBytecodeReader:GetFrameVariableName (self.Index)
end

function self:GetNameOrFallbackName ()
	local name = self.FunctionBytecodeReader:GetFrameVariableName (self.Index)
	if not name then
		if self:IsParameter () then
			name = "_param" .. tostring (self.Index - 1)
		else
			name = "_" .. tostring (self.Index - 1)
		end
	end
	return name
end

function self:GetTag (tagId)
	return self.FunctionBytecodeReader:GetFrameVariableTag (self.Index, tagId)
end

function self:IsParameter ()
	return self.Index <= self.FunctionBytecodeReader:GetParameterCount ()
end

--- Returns true if this is the first assignment
function self:SetAssigned (instructionId)
	local isFirstAssignment = self:GetTag ("FirstAssignment") == nil
	self:SetTag ("FirstAssignment", instructionId)
	return isFirstAssignment
end

function self:SetExpression (expression, indexable, rawValue)
	self:SetTag ("Expression", expression)
	self:SetTag ("ExpressionIndexable", indexable)
	self:SetTag ("ExpressionRawValue", rawValue)
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetTag (tagId, data)
	return self.FunctionBytecodeReader:SetFrameVariableTag (self.Index, tagId, data)
end