local self = {}
GLib.Net.InBuffer = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:GetBytesRemaining ()
	GLib.Error ("InBuffer:GetBytesRemaining : Not implemented.")
end

function self:GetPosition ()
	return self.Position
end

function self:GetSize ()
	GLib.Error ("InBuffer:GetSize : Not implemented.")
end

function self:IsEndOfStream ()
	GLib.Error ("InBuffer:IsEndOfStream : Not implemented.")
end

function self:Pin ()
	GLib.Error ("InBuffer:Pin : Not implemented.")
end

function self:UInt8 ()
	GLib.Error ("InBuffer:UInt8 : Not implemented.")
end

function self:UInt16 ()
	local low  = self:UInt8 ()
	local high = self:UInt8 ()
	return high * 256 + low
end

function self:UInt32 ()
	local low  = self:UInt16 ()
	local high = self:UInt16 ()
	return high * 65536 + low
end

function self:UInt64 ()
	local low  = self:UInt32 ()
	local high = self:UInt32 ()
	return high * 4294967296 + low
end

function self:Int8 ()
	GLib.Error ("InBuffer:Int8 : Not implemented.")
end

function self:Int16 ()
	local low  = self:UInt8 ()
	local high = self:Int8 ()
	return high * 256 + low
end

function self:Int32 ()
	local low  = self:UInt16 ()
	local high = self:Int16 ()
	return high * 65536 + low
end

function self:Int64 ()
	local low  = self:UInt32 ()
	local high = self:Int32 ()
	return high * 4294967296 + low
end

function self:Float ()
	local n = self:UInt32 ()
	return GLib.BitConverter.UInt32ToFloat (n)
end

function self:Double ()
	local low  = self:UInt32 ()
	local high = self:UInt32 ()
	return GLib.BitConverter.UInt32sToDouble (low, high)
end

function self:Vector ()
	local x = self:Float ()
	local y = self:Float ()
	local z = self:Float ()
	return Vector (x, y, z)
end

function self:Char ()
	return string.char (self:UInt8 ())
end

function self:Bytes ()
	GLib.Error ("InBuffer:Bytes : Not implemented.")
end

function self:String ()
	GLib.Error ("InBuffer:String : Not implemented.")
end

function self:Boolean ()
	return self:ReadUInt8 () ~= 0
end