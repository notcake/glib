local self = {}
GLib.StringInBuffer = GLib.MakeConstructor (self)

function self:ctor (data)
	self.Data = data or ""
	self.Position = 1
end

function self:IsEndOfStream ()
	return self.Position > self.Data:len ()
end

function self:UInt8 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	self.Position = self.Position + 1
	return n
end

function self:UInt16 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	self.Position = self.Position + 2
	return n
end

function self:UInt32 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position)) or 0
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	n = n + (string.byte (self.Data:sub (self.Position + 2, self.Position + 2)) or 0) * 65536
	n = n + (string.byte (self.Data:sub (self.Position + 3, self.Position + 3)) or 0) * 16777216
	self.Position = self.Position + 4
	return n
end

function self:UInt64 ()
	local n = string.byte (self.Data:sub (self.Position, self.Position))
	n = n + (string.byte (self.Data:sub (self.Position + 1, self.Position + 1)) or 0) * 256
	n = n + (string.byte (self.Data:sub (self.Position + 2, self.Position + 2)) or 0) * 65536
	n = n + (string.byte (self.Data:sub (self.Position + 3, self.Position + 3)) or 0) * 16777216
	n = n + (string.byte (self.Data:sub (self.Position + 4, self.Position + 4)) or 0) * 4294967296
	n = n + (string.byte (self.Data:sub (self.Position + 5, self.Position + 5)) or 0) * 1099511627776
	n = n + (string.byte (self.Data:sub (self.Position + 6, self.Position + 6)) or 0) * 281474976710656
	n = n + (string.byte (self.Data:sub (self.Position + 7, self.Position + 7)) or 0) * 72057594037927936
	self.Position = self.Position + 8
	return n
end

function self:Int8 ()
	local n = self:UInt8 ()
	if n >= 128 then n = n - 256 end
	return n
end

function self:Int16 ()
	local n = self:UInt16 ()
	if n >= 32768 then n = n - 65536 end
	return n
end

function self:Int32 ()
	local n = self:UInt32 ()
	if n >= 2147483648 then n = n - 4294967296 end
	return n
end

function self:Int64 ()
	local low = self:UInt32 ()
	local high = self:Int32 ()
	return high * 4294967296 + low
end

function self:Char ()
	local char = self.Data:sub (self.Position, self.Position)
	self.Position = self.Position + 1
	return char
end

function self:String ()
	local length = self:UInt16 ()
	local str = self.Data:sub (self.Position, self.Position + length - 1)
	self.Position = self.Position + length
	return str
end

function self:Boolean ()
	return self:UInt8 () == 1
end