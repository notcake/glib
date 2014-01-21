local self = {}
GLib.Lua.StackFrame = GLib.MakeConstructor (self)

function self:ctor (frameInfo, index)
	self.Index = index
	
	self.FrameInfo = frameInfo
	
	self.Locals   = {}
	self.Upvalues = {}
end

function self:GetData ()
	return self.FrameInfo
end

function self:GetIndex ()
	return self.Index
end

function self:IsNative ()
	return self.FrameInfo.what == "C"
end

function self:IsTrusted (...)
	if self:IsNative () then return true end
	
	return false
end

function self:IsUntrusted ()
	if self:IsNative () then return false end
	
	if file.Exists (self.FrameInfo.short_src, "GAME") or
	   GLib.Loader.File.Exists (self.FrameInfo.short_src, "LUA") then
		return false
	end
	
	return true
end

function self:ToString ()
	local name = self.FrameInfo.name
	local src  = self.FrameInfo.short_src
	src = src or "<unknown>"
	
	if name then
		return string.format ("%2d", self.Index) .. ": " .. name .. " (" .. src .. ": " .. tostring (self.FrameInfo.currentline) .. ")"
	elseif src and self.FrameInfo.currentline then
		return string.format ("%2d", self.Index) .. ": (" .. src .. ": " .. tostring (self.FrameInfo.currentline) .. ")"
	else
		return string.format ("%2d", self.Index) .. ": <unknown>"
	end
end

self.__tostring = self.ToString