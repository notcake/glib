local self = {}
GLib.Lua.StackTrace = GLib.MakeConstructor (self)

function self:ctor (levelCount, offset)
	levelCount = levelCount or math.huge
	offset = offset or 0
	offset = 4 + offset
	
	self.String = nil
	self.Hash = nil
	
	self.Frames = {}
	self.RawFrames = {}
	
	local i = offset
	local done = false
	
	local capturedLevelCount = 0
	while not done and
	      capturedLevelCount ~= levelCount do
		local stackFrame = debug.getinfo (i)
		self.RawFrames [#self.RawFrames + 1] = stackFrame
		
		if not stackFrame then done = true end
		if i > 100 then done = true end
		
		i = i + 1
		capturedLevelCount = capturedLevelCount + 1
	end
end

function self:ContainsUntrustedFrames ()
	for stackFrame in self:GetEnumerator () do
		if stackFrame:IsUntrusted () then
			return true
		end
	end
	
	return false
end

function self:GetAvailableFrameCount ()
	return #self.RawFrames
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self:GetFrame (i)
	end
end

function self:GetFrame (index)
	if not self.RawFrames [index] then return nil end
	
	if not self.Frames [index] then
		self.Frames [index] = GLib.Lua.StackFrame (self.RawFrames [index], index)
	end
	
	return self.Frames [index]
end

function self:GetFrameCount ()
	return #self.RawFrames
end

function self:GetHash ()
	if not self.Hash then
		self.Hash = util.CRC (self:ToString ())
	end
	
	return self.Hash
end

function self:IsFullyTrusted (...)
	for stackFrame in self:GetEnumerator () do
		if not stackFrame:IsTrusted (...) then
			return false
		end
	end
	return true
end

function self:ToString ()
	if not self.String then
		local stringBuilder = GLib.StringBuilder ()
		
		for i = 1, #self.RawFrames do
			local stackFrame = self.RawFrames [i]
			
			local name = stackFrame.name
			local src  = stackFrame.short_src
			src = src or "<unknown>"
			
			if name then
				stringBuilder:Append (string.format ("%2d", i - 1) .. ": " .. name .. " (" .. src .. ": " .. tostring (stackFrame.currentline) .. ")\n")
			else
				if src and stackFrame.currentline then
					stringBuilder:Append (string.format ("%2d", i - 1) .. ": (" .. src .. ": " .. tostring (stackFrame.currentline) .. ")\n")
				else
					stringBuilder:Append (string.format ("%2d", i - 1) .. ": <unknown>\n")
				end
			end
		end
		
		self.String = stringBuilder:ToString ()
	end
	
	return self.String
end

self.__tostring = self.ToString